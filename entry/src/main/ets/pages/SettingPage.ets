import { RuleIds } from '../logic/Rule';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { NavigationItem, PreferenceGroup, SwitchItem } from '../components/PreferenceGroup';
import { bundleManager } from '@kit.AbilityKit';

@ComponentV2
export struct SettingPage {
  @Local incognitoModeEnabled: boolean = false;
  @Local appVersion: string = '';

  async aboutToAppear(): Promise<void> {
    this.incognitoModeEnabled = PreferencesHelper.getBoolean(RuleIds.INCOGNITO_MODE, false);
    const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    this.appVersion = `v${bundleInfo.versionName} (${bundleInfo.versionCode})`;
  }

  build() {
    List() {
      ListItem() {
        PreferenceGroup({ title: $r('app.string.general') }) {
          SwitchItem({
            title: $r('app.string.incognito_mode'),
            summary: $r('app.string.incognito_mode_desc'),
            checked: this.incognitoModeEnabled,
            onChange: (value: boolean) => {
              this.incognitoModeEnabled = value;
              PreferencesHelper.setBoolean(RuleIds.INCOGNITO_MODE, value);
            },
          })
        }
      }

      ListItem() {
        PreferenceGroup({ title: $r('app.string.about') }) {
          NavigationItem({
            title: $r('app.string.about_limi'),
            summary: $r('app.string.version_label', this.appVersion),
            showArrow: false,
            onNavClick: () => {
            },
          })
        }
      }
    }.width('100%').height('100%').clip(false).edgeEffect(EdgeEffect.Spring)
  }
}
