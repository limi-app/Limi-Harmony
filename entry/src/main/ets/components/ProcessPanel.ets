import { ActionButton } from './ActionButton';

@ComponentV2
export struct ProcessPanel {
  @Param isEditing: boolean = false;
  @Param editText: string = '';
  @Param originalText: string = '';
  @Param processedText: string = '';
  @Param processedUrlList: string[] = [];
  @Param isProcessing: boolean = false;
  @Param isEmpty: boolean = false;
  @Param isNotHasUrls: boolean = false;
  @Param isError: boolean = false;
  @Param urlIcon: Resource = $r('sys.symbol.link');
  @Param showShareButton: boolean = false;
  @Local containerWidth: number = 360;
  @Local useAnimation: boolean = false;
  @Event onIsEditingChange: (value: boolean) => void = () => {
  };
  @Event onEditTextChange: (value: string) => void = () => {
  };
  @Event onOriginalTextChange: (value: string) => void = () => {
  };
  @Event onConfirm: (text: string) => void = () => {
  };
  @Event onCopy: (text: string) => void = () => {
  };
  @Event onShare: (text: string) => void = () => {
  };

  aboutToAppear(): void {
    setTimeout(() => {
      this.useAnimation = true;
    }, 50);
  }

  build() {
    Stack({ alignContent: Alignment.Start }) {
      if (this.isEditing) {
        Column() {
          this.EditView()
        }
        .width('100%')
        .transition(TransitionEffect.translate({ x: -(this.containerWidth + 32) })
          .animation({ duration: this.useAnimation ? 300 : 0, curve: Curve.FastOutSlowIn }))
      }
      if (!this.isEditing) {
        Column() {
          this.ProcessView()
        }
        .width('100%')
        .transition(TransitionEffect.translate({ x: this.containerWidth + 32 })
          .animation({ duration: this.useAnimation ? 300 : 0, curve: Curve.FastOutSlowIn }))
      }
    }
    .width('100%')
    .clip(false)
    .onAreaChange((_old: Area, newArea: Area) => {
      this.containerWidth = Number(newArea.width);
    })
  }

  @Builder
  EditView() {
    Column() {
      TextArea({ text: this.editText, placeholder: $r('app.string.input_or_paste_text') })
        .width('100%')
        .height(120)
        .fontSize(14)
        .onChange((value: string) => {
          this.onEditTextChange(value);
        })
        .margin({ bottom: 12 })

      Row({ space: 8 }) {
        ActionButton({
          icon: $r('sys.symbol.xmark'),
          label: $r('app.string.discard_and_back'),
          styleMode: ButtonStyleMode.NORMAL,
          isEnabled: this.originalText.length > 0,
          onButtonClick: () => {
            this.onIsEditingChange(false);
            this.onEditTextChange(this.originalText);
          },
        })

        ActionButton({
          icon: $r('sys.symbol.checkmark'),
          label: $r('app.string.confirm'),
          styleMode: ButtonStyleMode.EMPHASIZED,
          isEnabled: this.editText.trim().length > 0 &&
            (this.editText !== this.originalText || this.originalText.length === 0),
          onButtonClick: () => {
            this.onOriginalTextChange(this.editText);
            this.onIsEditingChange(false);
            this.onConfirm(this.editText);
          },
        })
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
        this.onIsEditingChange(true);
        this.onEditTextChange(this.originalText);
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
            SymbolGlyph(this.urlIcon)
              .fontSize(18)
              .fontColor([$r('sys.color.ohos_id_color_text_secondary')])

            Text(url)
              .fontSize(12)
              .fontColor($r('sys.color.ohos_id_color_text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }.padding(12).backgroundColor($r('sys.color.ohos_id_color_button_normal')).borderRadius(20).onClick(() => {
            this.onCopy(url);
          })
        }, (url: string, index: number) => `${index}`)
      }.clip(false)
    }
    .clip(false)
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .margin({ bottom: 12 })
    .scrollBar(BarState.Off)
    .align(Alignment.Start)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  ActionButtonsRow() {
    Row({ space: 8 }) {
      if (this.showShareButton) {
        ActionButton({
          icon: $r('sys.symbol.share'),
          label: $r('app.string.share'),
          styleMode: ButtonStyleMode.NORMAL,
          isEnabled: !this.isProcessing && !this.isEmpty && !this.isNotHasUrls && !this.isError &&
            this.processedText.length > 0,
          onButtonClick: () => {
            this.onShare(this.processedText);
          },
        })
      }

      ActionButton({
        icon: $r('sys.symbol.plus_square_on_square'),
        label: $r('app.string.copy'),
        styleMode: ButtonStyleMode.NORMAL,
        isEnabled: !this.isProcessing && !this.isEmpty && !this.isNotHasUrls && !this.isError &&
          this.processedText.length > 0,
        onButtonClick: () => {
          this.onCopy(this.processedText);
        },
      })
    }.width('100%')
  }
}
