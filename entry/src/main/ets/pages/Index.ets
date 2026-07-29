import {
  hdsMaterial,
  HdsNavigation,
  HdsNavigationTitle,
  HdsNavigationTitleBarOptions,
  HdsNavigationTitleMode,
  HdsTabs,
  HdsTabsController,
  ScrollEffectType,
  TitleBarContentOptions
} from '@kit.UIDesignKit';
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { RulePage } from './RulePage';
import { SettingPage } from './SettingPage';
import { HistoryDB } from '../utils/HistoryDB';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { LimiHistory } from '../model/LimiHistory';
import { processLinksInText } from '../logic/Rule';
import { RuleIds } from '../model/RuleIds';
import { HistoryDetailParams } from '../model/RouteParams';
import { NavigationItem, PreferenceGroup } from '../components/PreferenceGroup';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { i18n, intl } from '@kit.LocalizationKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';

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
@Component
struct Index {
  @State currentPage: number = 0;
  @State historyList: LimiHistory[] = [];
  @State showInputSheet: boolean = false;
  @State inputText: string = '';
  @State originalText: string = '';
  @State processedText: string = '';
  @State processedUrlList: string[] = [];
  @State isProcessing: boolean = false;
  @State isEmpty: boolean = false;
  @State isEditing: boolean = true;
  @State editText: string = '';
  @State customMaterialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;
  private tabController: HdsTabsController = new HdsTabsController();

  async aboutToAppear(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    await PreferencesHelper.init(context);
    await HistoryDB.init(context);
    await this.loadHistory();
    let materialTypes: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes();
    if (materialTypes.indexOf(hdsMaterial.MaterialType.IMMERSIVE) < 0) {
      this.customMaterialLevel = hdsMaterial.MaterialLevel.SMOOTH;
    }
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
    .titleBar(this.buildTitleBarOpts(this.currentPage === 0 ? 'Limi' : MENU_CONFIG[this.currentPage].label))
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
        this.inputText = '';
        this.originalText = '';
        this.editText = '';
        this.processedText = '';
        this.processedUrlList = [];
        this.isEditing = true;
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
            PreferenceGroup({ title: group.date }) {
              ForEach(group.items, (item: LimiHistory) => {
                NavigationItem({
                  maxLines: 3,
                  title: this.formatTime(item.datetime),
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
        }, (group: HistoryGroup) => group.date)
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
    .onClick(() => {
      this.isEditing = true;
      this.editText = '';
      this.originalText = '';
      this.showInputSheet = true;
    })
  }

  @Builder
  SheetContent() {
    Column() {
      if (this.isEditing) {
        this.EditView()
      } else {
        this.ProcessView()
      }
    }.width('100%').padding({ left: 16, right: 16, bottom: 40 })
  }

  @Builder
  EditView() {
    Column() {
      TextArea({ text: this.editText, placeholder: $r('app.string.input_or_paste_text') })
        .width('100%')
        .height(120)
        .fontSize(14)
        .onChange((value: string) => {
          this.editText = value;
        })
        .margin({ bottom: 12 })

      Row({ space: 8 }) {
        if (this.originalText.length > 0) {
          Button() {
            Row({ space: 6 }) {
              SymbolGlyph($r('sys.symbol.xmark')).fontSize(18).fontColor([$r('sys.color.ohos_id_color_text_primary')])
              Text($r('app.string.discard_and_back')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_primary'))
            }
          }.layoutWeight(1).height(40).buttonStyle(ButtonStyleMode.NORMAL).onClick(() => {
            this.isEditing = false;
          })
        } else {
          Button() {
            Row({ space: 6 }) {
              SymbolGlyph($r('sys.symbol.xmark'))
                .fontSize(18)
                .fontColor([$r('sys.color.ohos_id_color_text_primary')])
                .opacity(0.4)
              Text($r('app.string.discard_and_back'))
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .opacity(0.4)
            }
          }
          .layoutWeight(1)
          .height(40)
          .buttonStyle(ButtonStyleMode.NORMAL)
          .stateEffect(false)
          .enabled(false)
          .opacity(0.4)
        }

        if (this.editText.trim().length > 0 &&
          (this.editText !== this.originalText || this.originalText.length === 0)) {
          Button() {
            Row({ space: 6 }) {
              SymbolGlyph($r('sys.symbol.checkmark'))
                .fontSize(18)
                .fontColor([$r('sys.color.ohos_id_color_text_primary_contrary')])
              Text($r('app.string.confirm')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
            }
          }.layoutWeight(1).height(40).buttonStyle(ButtonStyleMode.EMPHASIZED).onClick(() => {
            this.originalText = this.editText;
            this.isEditing = false;
            this.processInputText();
          })
        } else {
          Button() {
            Row({ space: 6 }) {
              SymbolGlyph($r('sys.symbol.checkmark'))
                .fontSize(18)
                .fontColor([$r('sys.color.ohos_id_color_text_primary_contrary')])
                .opacity(0.4)
              Text($r('app.string.confirm'))
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
                .opacity(0.4)
            }
          }
          .layoutWeight(1)
          .height(40)
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .stateEffect(false)
          .enabled(false)
          .opacity(0.4)
        }
      }.width('100%')
    }.width('100%')
  }

  @Builder
  ProcessView() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(20)
          .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
          .padding({ right: 8 })
        Text($r('app.string.edit_original_text')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      .borderRadius(20)
      .margin({ bottom: 12 })
      .onClick(() => {
        this.isEditing = true;
        this.editText = this.originalText;
      })

      this.ResultCard()

      if (!this.isProcessing && this.processedUrlList.length > 0) {
        this.UrlListRow()
      }

      this.ActionButtonsRow()
    }.width('100%')
  }

  @Builder
  ResultCard() {
    Column() {
      if (this.isProcessing) {
        Row() {
          LoadingProgress().width(40).height(40).color($r('sys.color.ohos_id_color_emphasize'))
        }.width('100%').justifyContent(FlexAlign.Center).padding(12)
      } else if (this.processedText.length > 0) {
        Column() {
          Text($r('app.string.processing_results'))
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .margin({ bottom: 4 })

          Scroll() {
            Text(this.processedText)
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .width('100%')
              .copyOption(CopyOptions.LocalDevice)
          }.width('100%')
        }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
      }
    }.width('100%').backgroundColor($r('sys.color.ohos_id_color_button_normal')).borderRadius(20).margin({ bottom: 12 })
  }

  @Builder
  UrlListRow() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.processedUrlList, (url: string) => {
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.plus_square_on_square'))
              .fontSize(18)
              .fontColor([$r('sys.color.ohos_id_color_text_secondary')])

            Text(url)
              .fontSize(12)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }.padding(12).backgroundColor($r('sys.color.ohos_id_color_button_normal')).borderRadius(20).onClick(() => {
            this.copyText(url);
          })
        }, (url: string, index: number) => `${index}`)
      }.clip(false)
    }.clip(false).scrollable(ScrollDirection.Horizontal).width('100%').margin({ bottom: 12 }).scrollBar(BarState.Off).align(Alignment.Start).edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  ActionButtonsRow() {
    Row({ space: 8 }) {
      if (!this.isProcessing && !this.isEmpty && this.processedText.length > 0) {
        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.share')).fontSize(18).fontColor([$r('sys.color.ohos_id_color_text_primary')])
            Text($r('app.string.share')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_primary'))
          }
        }.layoutWeight(1).height(40).buttonStyle(ButtonStyleMode.NORMAL).onClick(() => {
          this.shareText(this.processedText);
        })
      } else {
        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.share'))
              .fontSize(18)
              .fontColor([$r('sys.color.ohos_id_color_text_primary')])
              .opacity(0.4)
            Text($r('app.string.share')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_primary')).opacity(0.4)
          }
        }
        .layoutWeight(1)
        .height(40)
        .buttonStyle(ButtonStyleMode.NORMAL)
        .stateEffect(false)
        .enabled(false)
        .opacity(0.4)
      }

      if (!this.isProcessing && !this.isEmpty && this.processedText.length > 0) {
        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.plus_square_on_square'))
              .fontSize(18)
              .fontColor([$r('sys.color.ohos_id_color_text_primary')])
            Text($r('app.string.copy')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_primary'))
          }
        }.layoutWeight(1).height(40).buttonStyle(ButtonStyleMode.NORMAL).onClick(() => {
          this.copyText(this.processedText);
        })
      } else {
        Button() {
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.plus_square_on_square'))
              .fontSize(18)
              .fontColor([$r('sys.color.ohos_id_color_text_primary')])
              .opacity(0.4)
            Text($r('app.string.copy')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_primary')).opacity(0.4)
          }
        }
        .layoutWeight(1)
        .height(40)
        .buttonStyle(ButtonStyleMode.NORMAL)
        .stateEffect(false)
        .enabled(false)
        .opacity(0.4)
      }
    }.width('100%')
  }

  async processInputText(): Promise<void> {
    if (this.originalText.length === 0) {
      this.processedText = '';
      this.processedUrlList = [];
      this.isEmpty = true;
      return;
    }

    this.processedText = '';
    this.processedUrlList = [];
    this.isProcessing = true;
    this.isEmpty = false;

    try {
      const result = await processLinksInText(this.originalText);
      if (result.isNotHasUrls) {
        this.processedText = this.originalText;
      } else {
        this.processedUrlList = result.processedUrlList;
        this.processedText = result.processedText;

        const incognito = await PreferencesHelper.getBoolean(RuleIds.INCOGNITO_MODE, false);
        if (!incognito) {
          const now = new Date();
          const datetime = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate())
            .padStart(2, '0')}T${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes())
            .padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}.${String(now.getMilliseconds())
            .padStart(3, '0')}`;
          const history = LimiHistory.create(this.originalText, this.processedText, datetime);
          await HistoryDB.insert(history);
          await this.loadHistory();
        }
      }
    } catch (e) {
      this.processedText = this.originalText;
    } finally {
      this.isProcessing = false;
    }
  }

  copyText(text: string): void {
    try {
      const pasteData = pasteboard.createPlainTextData(text);
      pasteboard.getSystemPasteboard().setData(pasteData);
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copied') });
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.copy_failed') });
    }
  }

  shareText(text: string): void {
    try {
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.TEXT, content: text
      });
      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE, previewMode: systemShare.SharePreviewMode.DEFAULT
      }).catch((err: BusinessError) => {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.share_failed') });
      });
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.share_failed') });
    }
  }

  formatDate(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      const locale = i18n.System.getSystemLocale();
      return new intl.DateTimeFormat(locale, { dateStyle: 'medium' }).format(date);
    } catch (e) {
      return dateStr.substring(0, dateStr.indexOf('T'));
    }
  }

  formatTime(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      const locale = i18n.System.getSystemLocale();
      return new intl.DateTimeFormat(locale, { timeStyle: 'medium' }).format(date);
    } catch (e) {
      return dateStr.substring(dateStr.indexOf('T') + 1, dateStr.lastIndexOf('.'));
    }
  }

  getGroupedHistory(): HistoryGroup[] {
    const groupMap: Record<string, LimiHistory[]> = {};
    const dateOrder: string[] = [];
    for (let i = 0; i < this.historyList.length; i++) {
      const item = this.historyList[i];
      const date = this.formatDate(item.datetime);
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

  private buildTitleBarOpts(title: string | Resource): HdsNavigationTitleBarOptions {
    const navTitle: HdsNavigationTitle = { mainTitle: title };
    const content: TitleBarContentOptions = { title: navTitle };
    const titleBar: HdsNavigationTitleBarOptions = {
      content: content, enableComponentSafeArea: true, style: {
        // 设置导航组件标题栏样式，推荐使用默认样式
        // 标题栏动态模糊样式，包括是否使能滚动动态模糊，动态模糊类型，动态模糊生效的滚动距离等
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20)
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: this.customMaterialLevel // 标题栏按钮沉浸光感效果跟随系统策略自适应
        },
        originalStyle: {
          // 内容区滚动前初始样式设置
          backgroundStyle: {
            // 标题栏背板样式设置
            backgroundColor: $r('sys.color.ohos_id_color_background'),
          }, contentStyle: {
            // 标题栏内容区样式设置，包括标题区域，菜单区域，返回按钮区域
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary'), subTitleColor: $r('sys.color.font_secondary')
            }, menuStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary')
            }, backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary')
            }
          }
        },
        scrollEffectStyle: {
          // 内容区滚动超过blurEffectiveEndOffset后样式设置
          backgroundStyle: {
            backgroundColor: $r('sys.color.ohos_id_color_background_transparent')
          }, contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary'), subTitleColor: $r('sys.color.font_secondary')
            }, menuStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary')
            }, backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary')
            }
          }
        }
      },
    };
    return titleBar;
  }
}
