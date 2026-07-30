import {
  hdsMaterial,
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsTabs,
  HdsTabsController
} from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { RulePage } from './RulePage';
import { spacingText } from 'pangu_cjk';
import { SettingPage } from './SettingPage';
import { HistoryDB } from '../utils/HistoryDB';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { LimiHistory } from '../data/model/LimiHistory';
import { processLinksInText } from '../logic/Rule';
import { HistoryDetailParams } from '../data/model/RouteParams';
import { NavigationItem, PreferenceGroup } from '../components/PreferenceGroup';
import { ProcessPanel } from '../components/ProcessPanel';
import { buildTitleBarOpts, getMaterialLevel } from '../components/TitleBarBuilder';
import { formatDate, formatTime } from '../utils/DateUtils';
import { copyToClipboard } from '../utils/ClipboardUtil';
import { saveHistoryIfEnabled } from '../utils/HistoryUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

interface MenuItem {
  symbolGlyph: SymbolGlyphModifier;
  symbolGlyph1: SymbolGlyphModifier;
  label: string | Resource;
}

const MENU_CONFIG: MenuItem[] = [{
  symbolGlyph: new SymbolGlyphModifier($r('sys.symbol.house')),
  symbolGlyph1: new SymbolGlyphModifier($r('sys.symbol.house_fill')),
  label: $r('app.string.home'),
}, {
  symbolGlyph: new SymbolGlyphModifier($r('sys.symbol.list_bullet')),
  symbolGlyph1: new SymbolGlyphModifier($r('sys.symbol.list_bullet')),
  label: $r('app.string.rule'),
}, {
  symbolGlyph: new SymbolGlyphModifier($r('sys.symbol.gearshape')),
  symbolGlyph1: new SymbolGlyphModifier($r('sys.symbol.gearshape_fill')),
  label: $r('app.string.setting'),
},];

class HistoryGroup {
  date: string = '';
  items: LimiHistory[] = [];
}

@Entry
@ComponentV2
struct Index {
  @Local currentPage: number = 0;
  @Local historyList: LimiHistory[] = [];
  @Local showInputSheet: boolean = false;
  @Local originalText: string = '';
  @Local processedText: string = '';
  @Local processedUrlList: string[] = [];
  @Local isProcessing: boolean = false;
  @Local isEmpty: boolean = false;
  @Local isNotHasUrls: boolean = false;
  @Local isError: boolean = false;
  @Local isEditing: boolean = true;
  @Local editText: string = '';
  @Local customMaterialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;
  private tabController: HdsTabsController = new HdsTabsController();

  async aboutToAppear(): Promise<void> {
    const hostContext = this.getUIContext().getHostContext();
    if (hostContext !== undefined) {
      const context = hostContext as common.UIAbilityContext;
      PreferencesHelper.init(context);
      await HistoryDB.init(context);
    }
    HistoryDB.setDataChangedCallback(() => {
      this.loadHistory();
    });
    await this.loadHistory();
    this.customMaterialLevel = getMaterialLevel();
  }

  async onPageShow(): Promise<void> {
    await this.loadHistory();
  }

  async loadHistory(): Promise<void> {
    this.historyList = await HistoryDB.getAllSortedByDatetimeDesc();
  }

  build() {
    HdsNavigation() {
      HdsTabs({ controller: this.tabController, index: this.currentPage }) {
        ForEach(MENU_CONFIG, (item: MenuItem, index: number) => {
          TabContent() {
            if (index === 0) {
              this.HomeContent()
            } else if (index === 1) {
              RulePage()
            } else {
              SettingPage()
            }
          }
          .clip(false)
          .padding({ bottom: 80 })
          .tabBar(new BottomTabBarStyle({ normal: item.symbolGlyph, selected: item.symbolGlyph1 }, item.label))
        }, (item: MenuItem, index: number) => `${index}`)
      }
      .barPosition(BarPosition.End)
      .barOverlap(true)
      .animationDuration(300)
      .vertical(false)
      .barFloatingStyle({
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE, materialLevel: this.customMaterialLevel,
        }, miniBar: {
          miniBarBuilder: () => this.miniBarBuilder(),
        },
      })
      .onChange((index: number) => {
        this.currentPage = index;
        if (index === 0) {
          this.loadHistory();
        }
      })
      .clip(false)
    }
    .titleMode(HdsNavigationTitleMode.MINI)
    .titleBar(buildTitleBarOpts(this.currentPage === 0 ? 'Limi' : MENU_CONFIG[this.currentPage].label,
      this.customMaterialLevel,))
    .hideBackButton(true)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .bindSheet(this.showInputSheet, this.SheetContent(), {
      height: SheetSize.FIT_CONTENT,
      showClose: true,
      title: { title: $r('app.string.process_link') },
      onDisappear: () => {
        this.showInputSheet = false;
        this.originalText = '';
        this.editText = '';
        this.processedText = '';
        this.processedUrlList = [];
        this.isEditing = true;
        this.isEmpty = false;
        this.isNotHasUrls = false;
        this.isError = false;
      },
    })
  }

  @Builder
  HomeContent() {
    if (this.historyList.length === 0) {
      Column() {
        Text($r('app.string.no_history')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_hint'))
      }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    } else {
      List({ space: 0 }) {
        ForEach(this.getGroupedHistory(), (group: HistoryGroup) => {
          ListItem() {
            PreferenceGroup({ title: spacingText(group.date) }) {
              ForEach(group.items, (item: LimiHistory) => {
                NavigationItem({
                  maxLines: 3,
                  title: formatTime(item.datetime),
                  summary: item.processedUrl,
                  onNavClick: () => {
                    const params: HistoryDetailParams = {
                      historyId: item.id,
                      originUrl: item.originUrl,
                      processedUrl: item.processedUrl,
                      datetime: item.datetime,
                    };
                    this.getUIContext().getRouter().pushUrl({ url: 'pages/HistoryDetail', params: params });
                  }
                })
              }, (item: LimiHistory) => item.id.toString())
            }
          }
        }, (group: HistoryGroup) => `${group.date}_${group.items.length}`)
      }.width('100%').height('100%').clip(false).edgeEffect(EdgeEffect.Spring)
    }
  }

  @Builder
  miniBarBuilder() {
    Row() {
      SymbolGlyph($r('sys.symbol.plus')).fontSize(24).fontColor([$r('sys.color.ohos_id_color_text_secondary')])
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .bindMenu([{
      value: $r('app.string.from_text'), icon: $r('sys.symbol.text_alignleft'), action: () => {
        this.openTextSheet();
      }
    }, {
      value: $r('app.string.scan_qrcode'), icon: $r('sys.symbol.qrcode'), action: () => {
        this.startScan();
      }
    }],
      {
        placement: Placement.BottomRight
      })
  }

  openTextSheet(): void {
    this.isEditing = true;
    this.editText = '';
    this.originalText = '';
    this.showInputSheet = true;
  }

  async startScan(): Promise<void> {
    try {
      const hostContext = this.getUIContext().getHostContext();
      if (hostContext === undefined) {
        return;
      }
      const context = hostContext as common.UIAbilityContext;
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE], enableMultiMode: true, enableAlbum: true,
      };
      const scanResult = await scanBarcode.startScanForResult(context, options);
      const text = scanResult.originalValue;
      if (text.length > 0) {
        this.isEditing = false;
        this.editText = text;
        this.originalText = text;
        this.showInputSheet = true;
        this.processInputText();
      }
    } catch (e) {
      const err = e as BusinessError;
      if (err.code !== 1000500002) {
        hilog.error(0x0001, '[Scan Sample]',
          `Failed to start the scanning service. Code:${err.code}, message: ${err.message}`);
      }
    }
  }

  @Builder
  SheetContent() {
    Column() {
      ProcessPanel({
        isEditing: this.isEditing,
        onIsEditingChange: (v: boolean) => {
          this.isEditing = v;
        },
        editText: this.editText,
        onEditTextChange: (v: string) => {
          this.editText = v;
        },
        originalText: this.originalText,
        onOriginalTextChange: (v: string) => {
          this.originalText = v;
        },
        processedText: this.processedText,
        processedUrlList: this.processedUrlList,
        isProcessing: this.isProcessing,
        isEmpty: this.isEmpty,
        isNotHasUrls: this.isNotHasUrls,
        isError: this.isError,
        showShareButton: true,
        onConfirm: (text: string) => {
          this.processInputText();
        },
        onCopy: (text: string) => {
          copyToClipboard(this.getUIContext(), text);
        },
        onShare: (text: string) => {
          this.shareText(text);
        },
      })
    }.width('100%').padding({ left: 16, right: 16, bottom: 40 })
  }

  async processInputText(): Promise<void> {
    this.isProcessing = true;
    this.isEmpty = false;
    this.isError = false;
    this.isNotHasUrls = false;

    try {
      const result = await processLinksInText(this.originalText);
      this.processedText = result.processedText;
      this.processedUrlList = result.processedUrlList;
      this.isEmpty = result.isEmpty;
      this.isNotHasUrls = result.isNotHasUrls;

      if (!result.isEmpty && !result.isNotHasUrls) {
        const saved = await saveHistoryIfEnabled(this.originalText, this.processedText);
        if (saved) {
          await this.loadHistory();
        }
      }
    } catch (e) {
      this.processedText = `${e}`;
      this.isError = true;
    } finally {
      this.isProcessing = false;
    }
  }

  shareText(text: string): void {
    try {
      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.TEXT, content: text
      });
      const controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      const hostContext = this.getUIContext().getHostContext();
      if (hostContext === undefined) {
        return;
      }
      const context: common.UIAbilityContext = hostContext as common.UIAbilityContext;
      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE, previewMode: systemShare.SharePreviewMode.DEFAULT
      }).catch((err: BusinessError) => {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.share_failed') });
      });
    } catch (e) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.share_failed') });
      } catch (err) {
        console.info(`showToast failed: ${err}`);
      }
    }
  }

  getGroupedHistory(): HistoryGroup[] {
    const groupMap: Record<string, LimiHistory[]> = {};
    const dateOrder: string[] = [];
    for (let i = 0; i < this.historyList.length; i++) {
      const item = this.historyList[i];
      const date = formatDate(item.datetime);
      if (groupMap[date] === undefined) {
        groupMap[date] = [];
        dateOrder.push(date);
      }
      groupMap[date].push(item);
    }
    const groups: HistoryGroup[] = [];
    for (let i = 0; i < dateOrder.length; i++) {
      const g = new HistoryGroup();
      g.date = dateOrder[i];
      g.items = groupMap[dateOrder[i]];
      groups.push(g);
    }
    return groups;
  }
}
