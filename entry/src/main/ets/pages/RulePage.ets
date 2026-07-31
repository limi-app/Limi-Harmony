import { RuleIds } from '../logic/Rule';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { ListGroupSection, PreferenceGroup, PreferenceItem, SwitchItem } from '../components/PreferenceGroup';

export enum RuleId {
  COMMON_PARAMS = 'common_params',
  UTM_PARAMS = 'utm_params',
  UTM_ENHANCED = 'utm_enhanced',
  BILIBILI = 'bilibili',
  X = 'x',
}

export class RuleItem implements PreferenceItem {
  id: RuleId = RuleId.COMMON_PARAMS;
  title: string | Resource = '';
  summary: string | Resource = '';
  prefKey: string = '';
}

@ComponentV2
export struct RulePage {
  @Local ruleStates: Map<RuleId, boolean> = new Map<RuleId, boolean>([
    [RuleId.COMMON_PARAMS, true],
    [RuleId.UTM_PARAMS, true],
    [RuleId.UTM_ENHANCED, false],
    [RuleId.BILIBILI, true],
    [RuleId.X, true],
  ]);
  private readonly commonRuleItems: RuleItem[] = [
    {
      id: RuleId.COMMON_PARAMS,
      title: $r('app.string.common_params_rule'),
      summary: $r('app.string.common_params_rule_desc'),
      prefKey: RuleIds.COMMON_PARAMS,
    },
    {
      id: RuleId.UTM_PARAMS,
      title: $r('app.string.utm_rule'),
      summary: $r('app.string.utm_rule_desc'),
      prefKey: RuleIds.UTM_PARAMS,
    },
    {
      id: RuleId.UTM_ENHANCED,
      title: $r('app.string.utm_enhanced_rule'),
      summary: $r('app.string.utm_enhanced_rule_desc'),
      prefKey: RuleIds.UTM_PARAMS_ENHANCED,
    },
  ];
  private readonly exceptionalRuleItems: RuleItem[] = [
    {
      id: RuleId.BILIBILI,
      title: $r('app.string.bilibili_rule'),
      summary: $r('app.string.bilibili_rule_desc'),
      prefKey: RuleIds.BILIBILI,
    },
    {
      id: RuleId.X,
      title: $r('app.string.x_rule'),
      summary: '',
      prefKey: RuleIds.X,
    },
  ];

  async aboutToAppear(): Promise<void> {
    this.ruleStates = new Map<RuleId, boolean>([
      [RuleId.COMMON_PARAMS, PreferencesHelper.getBoolean(RuleIds.COMMON_PARAMS, true)],
      [RuleId.UTM_PARAMS, PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS, true)],
      [RuleId.UTM_ENHANCED, PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS_ENHANCED, false)],
      [RuleId.BILIBILI, PreferencesHelper.getBoolean(RuleIds.BILIBILI, true)],
      [RuleId.X, PreferencesHelper.getBoolean(RuleIds.X, true)],
    ]);
  }

  isRuleEnabled(id: RuleId): boolean {
    const value = this.ruleStates.get(id);
    return value ?? false;
  }

  setRuleEnabled(id: RuleId, prefKey: string, value: boolean): void {
    const next = new Map<RuleId, boolean>(this.ruleStates);
    next.set(id, value);
    this.ruleStates = next;
    PreferencesHelper.setBoolean(prefKey, value);
  }

  getRuleSections(): ListGroupSection[] {
    return [
      new ListGroupSection($r('app.string.common_rules_group'), this.commonRuleItems),
      new ListGroupSection($r('app.string.exceptional_rules_group'), this.exceptionalRuleItems),
    ];
  }

  @Builder
  renderRuleItem(item: PreferenceItem, index: number) {
    SwitchItem({
      title: (item as RuleItem).title,
      summary: (item as RuleItem).summary,
      checked: this.isRuleEnabled((item as RuleItem).id),
      onChange: (value: boolean) => {
        this.setRuleEnabled((item as RuleItem).id, (item as RuleItem).prefKey, value);
      },
    })
  }

  build() {
    PreferenceGroup({
      sections: this.getRuleSections(),
      itemContent: (item: PreferenceItem, index: number) => {
        this.renderRuleItem(item, index);
      },
    })
  }
}
