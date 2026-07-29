import { HdsListItemCard, SuffixArrow, SuffixSwitch } from '@kit.UIDesignKit';
import { TextModifier } from '@kit.ArkUI';

@ComponentV2
export struct PreferenceGroup {
  @Param title: string | Resource = '';
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {
  }

  build() {
    Column() {
      if (typeof this.title === 'string' ? this.title.length > 0 : true) {
        Text(this.title)
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .fontWeight(FontWeight.Medium)
          .margin({
            bottom: 8,
            left: 24,
            right: 24,
            top: 16
          })
      }
      Column() {
        this.content()
      }.width('100%')
    }.width('100%').margin({ bottom: 8 }).alignItems(HorizontalAlign.Start)
  }
}

@ComponentV2
export struct SwitchItem {
  @Param title: string | Resource = '';
  @Param summary: string | Resource = '';
  @Param maxLines: number = 0;
  @Param checked: boolean = false;
  @Event onChange: (value: boolean) => void = () => {
  };

  build() {
    Column() {
      HdsListItemCard({
        textItem: {
          primaryText: {
            text: this.title
          }, description: {
            text: this.summary,
            modifier: this.maxLines
              ? new TextModifier()
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .maxLines(this.maxLines)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              : undefined
          }
        }, suffixItem: new SuffixSwitch({
          isCheck: this.checked, onChange: (isCheck: boolean) => {
            this.onChange(isCheck);
          }
        }),
      })
      Blank().height(12)
    }
  }
}

@ComponentV2
export struct NavigationItem {
  @Param title: string | Resource = '';
  @Param summary: string | Resource = '';
  @Param maxLines: number = 0;
  @Param showArrow: boolean = true;
  @Event onNavClick: () => void = () => {
  };

  build() {
    Column() {
      HdsListItemCard({
        textItem: {
          primaryText: {
            text: this.title
          }, description: {
            text: this.summary,
            modifier: this.maxLines
              ? new TextModifier()
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                .maxLines(this.maxLines)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              : undefined
          }
        },
        suffixItem: this.showArrow ? new SuffixArrow({ color: $r('sys.color.ohos_id_color_text_secondary') }) :
          undefined,
        onClick: () => {
          this.onNavClick();
        }
      })
      Blank().height(12)
    }
  }
}
