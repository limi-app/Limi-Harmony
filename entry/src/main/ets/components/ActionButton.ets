@ComponentV2
export struct ActionButton {
  @Param icon: Resource = $r('sys.symbol.checkmark');
  @Param label: string | Resource = '';
  @Param isEnabled: boolean = true;
  @Param styleMode: ButtonStyleMode = ButtonStyleMode.NORMAL;
  @Event onButtonClick: () => void = () => {
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
