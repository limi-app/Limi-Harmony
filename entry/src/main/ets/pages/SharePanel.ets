import { processLinksInText } from '../logic/Rule';
import { HistoryDB } from '../utils/HistoryDB';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { RuleIds } from '../model/RuleIds';
import { LimiHistory } from '../model/LimiHistory';
import { pasteboard } from '@kit.BasicServicesKit';
import { UIExtensionContentSession } from '@kit.AbilityKit';
import {
  hdsMaterial,
  HdsNavigation,
  HdsNavigationTitle,
  HdsNavigationTitleBarOptions,
  HdsNavigationTitleMode,
  ScrollEffectType,
  TitleBarContentOptions,
} from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';

@Entry
@Component
struct SharePanelPage {
  @State originalText: string = '';
  @State processedText: string = '';
  @State processedUrlList: string[] = [];
  @State isProcessing: boolean = false;
  @State isEditing: boolean = true;
  @State editText: string = '';
  @State isEmpty: boolean = false;
  @State isNotHasUrls: boolean = false;
  @State isError: boolean = false;
  @State customMaterialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;
  private storage: LocalStorage = LocalStorage.getShared();
  private session: UIExtensionContentSession | null = null;

  aboutToAppear(): void {
    const shareText = this.storage.get<string>('shareText') ?? '';
    const sessionObj = this.storage.get<UIExtensionContentSession>('session');
    if (sessionObj !== undefined && sessionObj !== null) {
      this.session = sessionObj;
    }
    if (shareText.length > 0) {
      this.originalText = shareText;
      this.editText = shareText;
      this.isEditing = false;
      this.processText(shareText);
    }
    let materialTypes: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes();
    if (materialTypes.indexOf(hdsMaterial.MaterialType.IMMERSIVE) <
      0) { // 当前设备不支持IMMERSIVE材质类型，则使用SMOOTH效果以优化性能，降低卡顿和发热风险
      this.customMaterialLevel = hdsMaterial.MaterialLevel.SMOOTH;
    }
  }

  async processText(text: string): Promise<void> {
    this.isProcessing = true;
    this.isEmpty = false;
    this.isError = false;
    this.isNotHasUrls = false;

    try {
      const result = await processLinksInText(text);
      this.processedText = result.processedText;
      this.processedUrlList = result.processedUrlList;
      this.isEmpty = result.isEmpty;
      this.isNotHasUrls = result.isNotHasUrls;

      if (!result.isEmpty && !result.isNotHasUrls) {
        const incognito = await PreferencesHelper.getBoolean(RuleIds.INCOGNITO_MODE, false);
        if (!incognito && this.originalText.length > 0 && this.processedText.length > 0) {
          const now = new Date();
          const datetime = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate())
            .padStart(2, '0')}T` +
            `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(
              now.getSeconds()).padStart(2, '0')}.${String(now.getMilliseconds()).padStart(3, '0')}`;
          const history = LimiHistory.create(this.originalText, this.processedText, datetime);
          await HistoryDB.insert(history);
        }
      }
    } catch (e) {
      this.processedText = `${e}`;
      this.isError = true;
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

  closeSession(): void {
    if (this.session !== null) {
      this.session.terminateSelf();
    }
  }

  build() {
    HdsNavigation() {
      Column() {
        if (this.isEditing) {
          this.EditView()
        } else {
          this.ProcessView()
        }
      }.width('100%').padding({ left: 16, right: 16, bottom: 8 })
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .titleMode(HdsNavigationTitleMode.MINI)
    .titleBar(this.buildTitleBarOpts())
    .padding({ top: 6 })
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

      Row() {
        if (this.originalText.length > 0) {
          Button() {
            Row({ space: 6 }) {
              SymbolGlyph($r('sys.symbol.xmark')).fontSize(18).fontColor([$r('sys.color.ohos_id_color_text_primary')])
              Text($r('app.string.discard_and_back')).fontSize(14).fontColor($r('sys.color.ohos_id_color_text_primary'))
            }
          }
          .layoutWeight(1)
          .height(40)
          .buttonStyle(ButtonStyleMode.NORMAL)
          .onClick(() => {
            this.isEditing = false;
            this.editText = this.originalText;
          })
          .margin({ right: 8 })
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
          .margin({ right: 8 })
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
            this.processText(this.editText);
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
      } else if (this.isEmpty) {
        Text($r('app.string.input_string_is_empty'))
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding(16)
      } else if (this.isNotHasUrls) {
        Text($r('app.string.no_links_found'))
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding(16)
      } else if (this.processedText.length > 0) {
        Column() {
          if (this.isError) {
            Text($r('app.string.processing_error', this.processedText))
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .width('100%')
          } else {
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
          }
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
            SymbolGlyph($r('sys.symbol.link')).fontSize(18).fontColor([$r('sys.color.ohos_id_color_text_secondary')])

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
      if (!this.isEmpty && !this.isProcessing && !this.isNotHasUrls && !this.isError) {
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

  private buildTitleBarOpts(): HdsNavigationTitleBarOptions {
    const navTitle: HdsNavigationTitle = { mainTitle: 'Limi' };
    const content: TitleBarContentOptions = {
      title: navTitle, backIcon: {
        action: (): void => {
          this.closeSession();
        }
      }
    };
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
