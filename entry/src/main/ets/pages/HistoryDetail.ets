import { router } from '@kit.ArkUI';
import { HistoryDetailParams } from '../data/model/RouteParams';
import { HistoryDB } from '../utils/HistoryDB';
import { buildTitleBarOpts, getMaterialLevel } from '../components/TitleBarBuilder';
import { formatDatetime } from '../utils/DateUtils';
import { spacingText } from 'pangu_cjk';
import {
  hdsMaterial, HdsNavigation, HdsNavigationTitleMode, IconStyleMode,
} from '@kit.UIDesignKit';

@Entry
@ComponentV2
struct HistoryDetail {
  @Local originUrl: string = '';
  @Local processedUrl: string = '';
  @Local datetime: string = '';
  @Local customMaterialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;
  private historyId: number = -1;

  aboutToAppear(): void {
    const params = router.getParams() as HistoryDetailParams;
    if (params !== null && params !== undefined) {
      this.historyId = params.historyId ?? -1;
      this.originUrl = params.originUrl ?? '';
      this.processedUrl = params.processedUrl ?? '';
      this.datetime = params.datetime ?? '';
    }
    this.customMaterialLevel = getMaterialLevel();
  }

  build() {
    HdsNavigation() {
      List({ space: 0 }) {
        ListItem() {
          Column({ space: 8 }) {
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

            Text($r('app.string.time_label'))
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontWeight(FontWeight.Medium)

            Text(spacingText(formatDatetime(this.datetime)))
              .fontSize(16)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .width('100%')
              .padding({ bottom: 12 })
          }.width('100%').padding(16).alignItems(HorizontalAlign.Start)
        }
      }.width('100%').height('100%').clip(false).edgeEffect(EdgeEffect.Spring)
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .titleMode(HdsNavigationTitleMode.MINI)
    .titleBar(buildTitleBarOpts($r('app.string.history_detail'), this.customMaterialLevel, {
      menu: {
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
    }))
    .hideTitleBar(false)
  }

  async deleteHistory(): Promise<void> {
    if (this.historyId >= 0) {
      await HistoryDB.deleteById(this.historyId);
      this.getUIContext().getRouter().back();
    }
  }

  showDeleteConfirmDialog(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.confirm_delete_title'),
      message: $r('app.string.confirm_delete_message'),
      buttons: [{ text: $r('app.string.cancel'), color: $r('sys.color.brand') },
        { text: $r('app.string.confirm'), color: $r('sys.color.ohos_id_color_warning') }]
    }).then((result) => {
      if (result.index === 1) {
        this.deleteHistory();
      }
    });
  }
}
