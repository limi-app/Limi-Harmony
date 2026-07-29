@Component
export struct ActionButton {
  @Prop icon: Resource = $r('sys.symbol.checkmark');
  @Prop label: string | Resource = '';
  @Prop isEnabled: boolean = true;
  @Prop styleMode: ButtonStyleMode = ButtonStyleMode.NORMAL;
  onButtonClick: () => void = () => {
  };

  build() {
    if (this.isEnabled) {
      Button() {
        Row({ space: 6 }) {
          SymbolGlyph(this.icon)
            .fontSize(18)
            .fontColor([this.styleMode === ButtonStyleMode.EMPHASIZED
              ? $r('sys.color.ohos_id_color_text_primary_contrary')
              : $r('sys.color.ohos_id_color_text_primary')])
          Text(this.label)
            .fontSize(14)
            .fontColor(this.styleMode === ButtonStyleMode.EMPHASIZED
              ? $r('sys.color.ohos_id_color_text_primary_contrary')
              : $r('sys.color.ohos_id_color_text_primary'))
        }
      }
      .layoutWeight(1)
      .height(40)
      .buttonStyle(this.styleMode)
      .onClick(() => {
        this.onButtonClick();
      })
    } else {
      Button() {
        Row({ space: 6 }) {
          SymbolGlyph(this.icon)
            .fontSize(18)
            .fontColor([this.styleMode === ButtonStyleMode.EMPHASIZED
              ? $r('sys.color.ohos_id_color_text_primary_contrary')
              : $r('sys.color.ohos_id_color_text_primary')])
            .opacity(0.4)
          Text(this.label)
            .fontSize(14)
            .fontColor(this.styleMode === ButtonStyleMode.EMPHASIZED
              ? $r('sys.color.ohos_id_color_text_primary_contrary')
              : $r('sys.color.ohos_id_color_text_primary'))
            .opacity(0.4)
        }
      }
      .layoutWeight(1)
      .height(40)
      .buttonStyle(this.styleMode)
      .stateEffect(false)
      .enabled(false)
    }
  }
}
