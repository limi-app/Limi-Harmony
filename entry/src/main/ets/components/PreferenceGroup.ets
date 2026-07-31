import { HdsListItemCard, SuffixArrow, SuffixSwitch } from '@kit.UIDesignKit';
import { TextModifier } from '@kit.ArkUI';

/**
 * 标记接口：所有可被 PreferenceGroup 渲染的列表项类型应实现此接口。
 */
export interface PreferenceItem {
}

export class ListGroupSection {
  title: string | Resource = '';
  items: PreferenceItem[] = [];

  constructor(title: string | Resource = '', items: PreferenceItem[] = []) {
    this.title = title;
    this.items = items;
  }
}

@ComponentV2
export struct PreferenceGroup {
  @Param sections: ListGroupSection[] = [];
  @Param space: number = 12;
  @Param cardRadius: number = 21;
  @BuilderParam itemContent: (item: PreferenceItem, index: number) => void = this.defaultItemContent;

  @Builder
  defaultItemContent(item: PreferenceItem, index: number) {
  }

  hasTitle(section: ListGroupSection): boolean {
    if (typeof section.title === 'string') {
      return section.title.length > 0;
    }
    return true;
  }

  build() {
    List({ space: this.space }) {
      ForEach(this.sections, (section: ListGroupSection, sectionIndex: number) => {
        if (this.hasTitle(section)) {
          ListItem() {
            Text(section.title)
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontWeight(FontWeight.Medium)
              .margin({ top: 12, left: 14 })
          }
        }
        ListItem() {
          Column() {
            ForEach(section.items, (item: PreferenceItem, itemIndex: number) => {
              Column() {
                this.itemContent(item, itemIndex)
              }.width('100%')

              if (itemIndex < section.items.length - 1) {
                Divider().strokeWidth(1).color($r('sys.color.comp_background_tertiary')).margin({ left: 9, right: 9 })
              }
            }, (item: PreferenceItem, itemIndex: number) => `${sectionIndex}_${itemIndex}`)
          }
          .width('100%')
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius(this.cardRadius)
          .padding({
            left: 6,
            right: 6,
            top: 6,
            bottom: 6
          })
          .clip(true)
        }
      }, (section: ListGroupSection, sectionIndex: number) => `${sectionIndex}`)
    }
    .width('100%')
    .height('100%')
    .padding({
      left: 16,
      right: 16
    })
    .clip(false)
    .cachedCount(4, true)
    .edgeEffect(EdgeEffect.Spring)
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

  hasSummary(): boolean {
    if (typeof this.summary === 'string') {
      return this.summary.length > 0;
    }
    return true;
  }

  build() {
    HdsListItemCard({
      textItem: {
        primaryText: {
          text: this.title
        }, description: this.hasSummary() ? {
          text: this.summary,
          modifier: this.maxLines ? new TextModifier().fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(this.maxLines)
            .textOverflow({ overflow: TextOverflow.Ellipsis }) : undefined
        } : undefined
      },
      suffixItem: new SuffixSwitch({
        isCheck: this.checked, onChange: (isCheck: boolean) => {
          this.onChange(isCheck);
        }
      }),
      cardPrefixMargin: 0,
      cardSuffixMargin: 0,
      cardBackgroundColor: $r('sys.color.ohos_id_color_background_transparent')
    })
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

  hasSummary(): boolean {
    if (typeof this.summary === 'string') {
      return this.summary.length > 0;
    }
    return true;
  }

  build() {
    HdsListItemCard({
      textItem: {
        primaryText: {
          text: this.title
        }, description: this.hasSummary() ? {
          text: this.summary,
          modifier: this.maxLines ? new TextModifier().fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .maxLines(this.maxLines)
            .textOverflow({ overflow: TextOverflow.Ellipsis }) : undefined
        } : undefined
      },
      suffixItem: this.showArrow ? new SuffixArrow({ color: $r('sys.color.ohos_id_color_text_secondary') }) : undefined,
      cardPrefixMargin: 0,
      cardSuffixMargin: 0,
      cardBackgroundColor: $r('sys.color.ohos_id_color_background_transparent'),
      onClick: () => {
        this.onNavClick();
      }
    })
  }
}
