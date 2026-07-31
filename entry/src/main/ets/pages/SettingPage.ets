import { RuleIds } from '../logic/Rule';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { ListGroupSection, NavigationItem, PreferenceGroup, SwitchItem } from '../components/PreferenceGroup';
import { bundleManager } from '@kit.AbilityKit';

export class SettingItem {
  kind: string = '';
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
    const generalItems: SettingItem[] = [{ kind: 'incognito' }];
    const aboutItems: SettingItem[] = [{ kind: 'about_limi' }];
    const general = new ListGroupSection();
    general.title = $r('app.string.general');
    general.items = generalItems;
    const about = new ListGroupSection();
    about.title = $r('app.string.about');
    about.items = aboutItems;
    return [general, about];
  }

  @Builder
  renderSettingItem(item: object, index: number) {
    if ((item as SettingItem).kind === 'incognito') {
      SwitchItem({
        title: $r('app.string.incognito_mode'),
        summary: $r('app.string.incognito_mode_desc'),
        checked: this.incognitoModeEnabled,
        onChange: (value: boolean) => {
          this.incognitoModeEnabled = value;
          PreferencesHelper.setBoolean(RuleIds.INCOGNITO_MODE, value);
        },
      })
    } else {
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
      itemContent: (item: object, index: number) => {
        this.renderSettingItem(item, index);
      },
    })
  }
}
