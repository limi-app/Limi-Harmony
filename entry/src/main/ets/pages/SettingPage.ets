import { RuleIds } from '../logic/Rule';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { ListGroupSection, NavigationItem, PreferenceGroup, PreferenceItem, SwitchItem } from '../components/PreferenceGroup';
import { bundleManager } from '@kit.AbilityKit';

export enum SettingKind {
  INCOGNITO = 'incognito',
  ABOUT_LIMI = 'about_limi',
}

export interface SettingItem extends PreferenceItem {
  kind: SettingKind;
}

@ComponentV2
export struct SettingPage {
  @Local incognitoModeEnabled: boolean = false;
  @Local appVersion: string = '';

  async aboutToAppear(): Promise<void> {
    this.incognitoModeEnabled = PreferencesHelper.getBoolean(RuleIds.INCOGNITO_MODE, false);
    const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
    this.appVersion = `v${bundleInfo.versionName} (${bundleInfo.versionCode})`;
  }

  getSettingSections(): ListGroupSection[] {
    const generalItems: SettingItem[] = [{ kind: SettingKind.INCOGNITO }];
    const aboutItems: SettingItem[] = [{ kind: SettingKind.ABOUT_LIMI }];
    return [
      new ListGroupSection($r('app.string.general'), generalItems),
      new ListGroupSection($r('app.string.about'), aboutItems),
    ];
  }

  @Builder
  renderSettingItem(item: PreferenceItem, index: number) {
    if ((item as SettingItem).kind === SettingKind.INCOGNITO) {
      SwitchItem({
        title: $r('app.string.incognito_mode'),
        summary: $r('app.string.incognito_mode_desc'),
        checked: this.incognitoModeEnabled,
        onChange: (value: boolean) => {
          this.incognitoModeEnabled = value;
          PreferencesHelper.setBoolean(RuleIds.INCOGNITO_MODE, value);
        },
      })
    } else if ((item as SettingItem).kind === SettingKind.ABOUT_LIMI) {
      NavigationItem({
        title: $r('app.string.about_limi'),
        summary: $r('app.string.version_label', this.appVersion),
        showArrow: false,
        onNavClick: () => {
        },
      })
    }
  }

  build() {
    PreferenceGroup({
      sections: this.getSettingSections(),
      itemContent: (item: PreferenceItem, index: number) => {
        this.renderSettingItem(item, index);
      },
    })
  }
}
