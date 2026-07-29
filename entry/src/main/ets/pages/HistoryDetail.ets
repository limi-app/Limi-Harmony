import { LengthMetrics, router, promptAction } from '@kit.ArkUI';
import { HistoryDetailParams } from '../model/RouteParams';
import { HistoryDB } from '../utils/HistoryDB';
import { PreferenceGroup } from '../components/PreferenceGroup';
import { intl, i18n } from '@kit.LocalizationKit';
import {
  hdsMaterial,
  HdsNavigation,
  HdsNavigationTitle,
  HdsNavigationTitleBarOptions,
  HdsNavigationTitleMode,
  IconStyleMode,
  ScrollEffectType,
  TitleBarContentOptions,
} from '@kit.UIDesignKit';

@Entry
@Component
struct HistoryDetail {
  @State originUrl: string = '';
  @State processedUrl: string = '';
  @State datetime: string = '';
  @State customMaterialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;
  private historyId: number = -1;

  aboutToAppear(): void {
    const params = router.getParams() as HistoryDetailParams;
    if (params !== null && params !== undefined) {
      this.historyId = params.historyId ?? -1;
      this.originUrl = params.originUrl ?? '';
      this.processedUrl = params.processedUrl ?? '';
      this.datetime = params.datetime ?? '';
    }
    let materialTypes: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes();
    if (materialTypes.indexOf(hdsMaterial.MaterialType.IMMERSIVE) <
      0) { // 当前设备不支持IMMERSIVE材质类型，则使用SMOOTH效果以优化性能，降低卡顿和发热风险
      this.customMaterialLevel = hdsMaterial.MaterialLevel.SMOOTH;
    }
  }

  build() {
    HdsNavigation() {
      List({ space: 0 }) {
        ListItem() {
          Column({ space: 8 }) {
            // 处理结果
            Text($r('app.string.processing_results'))
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontWeight(FontWeight.Medium)

            Text(this.processedUrl)
              .fontSize(16)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .copyOption(CopyOptions.LocalDevice)
              .width('100%')
              .padding({ bottom: 12 })

            // 原始链接
            Text($r('app.string.original_text'))
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontWeight(FontWeight.Medium)

            Text(this.originUrl)
              .fontSize(16)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .copyOption(CopyOptions.LocalDevice)
              .width('100%')
              .padding({ bottom: 12 })

            // 时间
            Text($r('app.string.time_label'))
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontWeight(FontWeight.Medium)

            Text(this.formatDatetime(this.datetime))
              .fontSize(16)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .width('100%')
              .padding({ bottom: 12 })
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .height('100%')
      .clip(false)
      .edgeEffect(EdgeEffect.Spring)
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .titleMode(HdsNavigationTitleMode.MINI)
    .titleBar(this.buildTitleBarOpts($r('app.string.history_detail')))
    .hideTitleBar(false)
  }

  async deleteHistory(): Promise<void> {
    if (this.historyId >= 0) {
      await HistoryDB.deleteById(this.historyId);
      router.back();
    }
  }

  showDeleteConfirmDialog(): void {
    promptAction.showDialog({
      title: $r('app.string.confirm_delete_title'),
      message: $r('app.string.confirm_delete_message'),
      buttons: [
        { text: $r('app.string.cancel'), color: $r('sys.color.brand') },
        { text: $r('app.string.confirm'), color: $r('sys.color.ohos_id_color_warning') }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.deleteHistory();
      }
    });
  }

  formatDatetime(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      const locale = i18n.System.getSystemLocale();
      return new intl.DateTimeFormat(locale, { dateStyle: 'medium', timeStyle: 'medium' }).format(date);
    } catch (e) {
      return dateStr;
    }
  }

  private buildTitleBarOpts(title: string | Resource): HdsNavigationTitleBarOptions {
    const navTitle: HdsNavigationTitle = { mainTitle: title };
    const content: TitleBarContentOptions = {
      title: navTitle, menu: {
        value: [{
          content: {
            label: $r('app.string.delete'),
            icon: $r('sys.symbol.trash'),
            type: IconStyleMode.NORMAL,
            isEnabled: true,
            componentId: 'delete',
            action: () => {
              this.showDeleteConfirmDialog();
            }
          }
        }]
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
