import { HdsListItemCard, SuffixArrow, SuffixSwitch } from '@kit.UIDesignKit';
import { TextModifier } from '@kit.ArkUI';

@Component
export struct PreferenceGroup {
  @Prop title: string | Resource = '';
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

@Component
export struct SwitchItem {
  @Prop title: string | Resource = '';
  @Prop summary: string | Resource = '';
  @Prop maxLines: number = 0;
  @Prop checked: boolean = false;
  onChange: (value: boolean) => void = () => {
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
            this.checked = isCheck;
            this.onChange(isCheck);
          }
        }),
      })
      Blank().height(12)
    }
  }
}

@Component
export struct NavigationItem {
  @Prop title: string | Resource = '';
  @Prop summary: string | Resource = '';
  @Prop maxLines: number = 0;
  @Prop showArrow: boolean = true;
  onNavClick: () => void = () => {
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
