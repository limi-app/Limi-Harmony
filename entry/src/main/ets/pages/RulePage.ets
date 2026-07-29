import { RuleIds } from '../logic/Rule';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { PreferenceGroup, SwitchItem } from '../components/PreferenceGroup';

@ComponentV2
export struct RulePage {
  @Local commonParamsEnabled: boolean = true;
  @Local utmParamsEnabled: boolean = true;
  @Local utmParamsEnhancedEnabled: boolean = false;
  @Local bilibiliEnabled: boolean = true;
  @Local xEnabled: boolean = true;

  async aboutToAppear(): Promise<void> {
    this.commonParamsEnabled = PreferencesHelper.getBoolean(RuleIds.COMMON_PARAMS, true);
    this.utmParamsEnabled = PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS, true);
    this.utmParamsEnhancedEnabled = PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS_ENHANCED, false);
    this.bilibiliEnabled = PreferencesHelper.getBoolean(RuleIds.BILIBILI, true);
    this.xEnabled = PreferencesHelper.getBoolean(RuleIds.X, true);
  }

  build() {
    List() {
      ListItem() {
        PreferenceGroup({ title: $r('app.string.common_rules_group') }) {
          SwitchItem({
            title: $r('app.string.common_params_rule'),
            summary: $r('app.string.common_params_rule_desc'),
            checked: this.commonParamsEnabled,
            onChange: (value: boolean) => {
              this.commonParamsEnabled = value;
              PreferencesHelper.setBoolean(RuleIds.COMMON_PARAMS, value);
            },
          })
          SwitchItem({
            title: $r('app.string.utm_rule'),
            summary: $r('app.string.utm_rule_desc'),
            checked: this.utmParamsEnabled,
            onChange: (value: boolean) => {
              this.utmParamsEnabled = value;
              PreferencesHelper.setBoolean(RuleIds.UTM_PARAMS, value);
            },
          })
          SwitchItem({
            title: $r('app.string.utm_enhanced_rule'),
            summary: $r('app.string.utm_enhanced_rule_desc'),
            checked: this.utmParamsEnhancedEnabled,
            onChange: (value: boolean) => {
              this.utmParamsEnhancedEnabled = value;
              PreferencesHelper.setBoolean(RuleIds.UTM_PARAMS_ENHANCED, value);
            },
          })
        }
      }

      ListItem() {
        PreferenceGroup({ title: $r('app.string.exceptional_rules_group') }) {
          SwitchItem({
            title: $r('app.string.bilibili_rule'),
            summary: $r('app.string.bilibili_rule_desc'),
            checked: this.bilibiliEnabled,
            onChange: (value: boolean) => {
              this.bilibiliEnabled = value;
              PreferencesHelper.setBoolean(RuleIds.BILIBILI, value);
            },
          })
          SwitchItem({
            title: $r('app.string.x_rule'),
            checked: this.xEnabled,
            onChange: (value: boolean) => {
              this.xEnabled = value;
              PreferencesHelper.setBoolean(RuleIds.X, value);
            },
          })
        }
      }
    }
    .width('100%').height('100%').clip(false).edgeEffect(EdgeEffect.Spring)
  }
}
