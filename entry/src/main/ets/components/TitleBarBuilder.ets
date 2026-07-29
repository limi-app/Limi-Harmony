import {
  hdsMaterial,
  HdsNavigationTitle,
  HdsNavigationTitleBarOptions,
  ScrollEffectType,
  TitleBarContentOptions,
} from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';

export function buildTitleBarOpts(
  title: string | Resource,
  materialLevel: hdsMaterial.MaterialLevel,
  contentOverrides?: Partial<TitleBarContentOptions>,
): HdsNavigationTitleBarOptions {
  const navTitle: HdsNavigationTitle = { mainTitle: title };
  const content: TitleBarContentOptions = { title: navTitle };
  if (contentOverrides !== undefined) {
    if (contentOverrides.backIcon !== undefined) {
      content.backIcon = contentOverrides.backIcon;
    }
    if (contentOverrides.menu !== undefined) {
      content.menu = contentOverrides.menu;
    }
  }
  return {
    content: content,
    enableComponentSafeArea: true,
    style: {
      scrollEffectOpts: {
        enableScrollEffect: true,
        scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR,
        blurEffectiveStartOffset: LengthMetrics.vp(0),
        blurEffectiveEndOffset: LengthMetrics.vp(20)
      },
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.ADAPTIVE,
        materialLevel: materialLevel
      },
      originalStyle: {
        backgroundStyle: {
          backgroundColor: $r('sys.color.ohos_id_color_background'),
        },
        contentStyle: {
          titleStyle: {
            mainTitleColor: $r('sys.color.font_primary'),
            subTitleColor: $r('sys.color.font_secondary')
          },
          menuStyle: {
            backgroundColor: $r('sys.color.comp_background_tertiary'),
            iconColor: $r('sys.color.icon_primary')
          },
          backIconStyle: {
            backgroundColor: $r('sys.color.comp_background_tertiary'),
            iconColor: $r('sys.color.icon_primary')
          }
        }
      },
      scrollEffectStyle: {
        backgroundStyle: {
          backgroundColor: $r('sys.color.ohos_id_color_background_transparent')
        },
        contentStyle: {
          titleStyle: {
            mainTitleColor: $r('sys.color.font_primary'),
            subTitleColor: $r('sys.color.font_secondary')
          },
          menuStyle: {
            backgroundColor: $r('sys.color.comp_background_tertiary'),
            iconColor: $r('sys.color.icon_primary')
          },
          backIconStyle: {
            backgroundColor: $r('sys.color.comp_background_tertiary'),
            iconColor: $r('sys.color.icon_primary')
          }
        }
      }
    },
  };
}

export function getMaterialLevel(): hdsMaterial.MaterialLevel {
  const materialTypes: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes();
  if (materialTypes.indexOf(hdsMaterial.MaterialType.IMMERSIVE) < 0) {
    return hdsMaterial.MaterialLevel.SMOOTH;
  }
  return hdsMaterial.MaterialLevel.EXQUISITE;
}
