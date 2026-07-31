import { RuleIds } from '../logic/Rule';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { ListGroupSection, PreferenceGroup, SwitchItem } from '../components/PreferenceGroup';

export class RuleItem {
  id: string = '';
  title: string | Resource = '';
  summary: string | Resource = '';
}

@ComponentV2
export struct RulePage {
  @Local commonParamsEnabled: boolean = true;
  @Local utmParamsEnabled: boolean = true;
  @Local utmParamsEnhancedEnabled: boolean = false;
  @Local bilibiliEnabled: boolean = true;
  @Local xEnabled: boolean = true;
  private readonly commonRuleItems: RuleItem[] = [
    {
      id: 'common_params',
      title: $r('app.string.common_params_rule'),
      summary: $r('app.string.common_params_rule_desc')
    },
    {
      id: 'utm_params',
      title: $r('app.string.utm_rule'),
      summary: $r('app.string.utm_rule_desc')
    },
    {
      id: 'utm_enhanced',
      title: $r('app.string.utm_enhanced_rule'),
      summary: $r('app.string.utm_enhanced_rule_desc')
    },
  ];
  private readonly exceptionalRuleItems: RuleItem[] = [
    {
      id: 'bilibili',
      title: $r('app.string.bilibili_rule'),
      summary: $r('app.string.bilibili_rule_desc')
    },
    {
      id: 'x',
      title: $r('app.string.x_rule'),
      summary: ''
    },
  ];

  async aboutToAppear(): Promise<void> {
    this.commonParamsEnabled = PreferencesHelper.getBoolean(RuleIds.COMMON_PARAMS, true);
    this.utmParamsEnabled = PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS, true);
    this.utmParamsEnhancedEnabled = PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS_ENHANCED, false);
    this.bilibiliEnabled = PreferencesHelper.getBoolean(RuleIds.BILIBILI, true);
    this.xEnabled = PreferencesHelper.getBoolean(RuleIds.X, true);
  }

  isRuleEnabled(id: string): boolean {
    if (id === 'common_params') {
      return this.commonParamsEnabled;
    }
    if (id === 'utm_params') {
      return this.utmParamsEnabled;
    }
    if (id === 'utm_enhanced') {
      return this.utmParamsEnhancedEnabled;
    }
    if (id === 'bilibili') {
      return this.bilibiliEnabled;
    }
    return this.xEnabled;
  }

  setRuleEnabled(id: string, value: boolean): void {
    if (id === 'common_params') {
      this.commonParamsEnabled = value;
      PreferencesHelper.setBoolean(RuleIds.COMMON_PARAMS, value);
    } else if (id === 'utm_params') {
      this.utmParamsEnabled = value;
      PreferencesHelper.setBoolean(RuleIds.UTM_PARAMS, value);
    } else if (id === 'utm_enhanced') {
      this.utmParamsEnhancedEnabled = value;
      PreferencesHelper.setBoolean(RuleIds.UTM_PARAMS_ENHANCED, value);
    } else if (id === 'bilibili') {
      this.bilibiliEnabled = value;
      PreferencesHelper.setBoolean(RuleIds.BILIBILI, value);
    } else {
      this.xEnabled = value;
      PreferencesHelper.setBoolean(RuleIds.X, value);
    }
  }

  getRuleSections(): ListGroupSection[] {
    const common = new ListGroupSection();
    common.title = $r('app.string.common_rules_group');
    common.items = this.commonRuleItems;
    const exceptional = new ListGroupSection();
    exceptional.title = $r('app.string.exceptional_rules_group');
    exceptional.items = this.exceptionalRuleItems;
    return [common, exceptional];
  }

  @Builder
  renderRuleItem(item: object, index: number) {
    SwitchItem({
      title: (item as RuleItem).title,
      summary: (item as RuleItem).summary,
      checked: this.isRuleEnabled((item as RuleItem).id),
      onChange: (value: boolean) => {
        this.setRuleEnabled((item as RuleItem).id, value);
      },
    })
  }

  build() {
    PreferenceGroup({
      sections: this.getRuleSections(),
      itemContent: (item: object, index: number) => {
        this.renderRuleItem(item, index);
      },
    })
  }
}
