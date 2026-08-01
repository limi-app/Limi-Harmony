import { RuleIds } from '../logic/Rule';
import { PreferencesHelper } from '../utils/PreferencesHelper';
import { ListGroupSection, PreferenceGroup, PreferenceItem, SwitchItem } from '../components/PreferenceGroup';
import { formatTimestamp } from '../utils/DateUtils';
import { spacingText } from 'pangu_cjk';

/**
 * 规则标识常量，值派生自 RuleIds，确保唯一真实来源。
 * 使用 const 对象替代 enum：ArkTS 不支持字符串枚举的计算成员。
 */
export class RuleId {
  static readonly UTM_PARAMS: string = RuleIds.UTM_PARAMS;
  static readonly UTM_ENHANCED: string = RuleIds.UTM_PARAMS_ENHANCED;
  static readonly FIREFOX_QUERY_STRIPPING: string = RuleIds.FIREFOX_QUERY_STRIPPING;
  static readonly BRAVE_CLEAN_URLS: string = RuleIds.BRAVE_CLEAN_URLS;
  static readonly BRAVE_DEBOUNCE: string = RuleIds.BRAVE_DEBOUNCE;
  static readonly BRAVE_QUERY_FILTER: string = RuleIds.BRAVE_QUERY_FILTER;
  static readonly CLEAR_URLS: string = RuleIds.CLEAR_URLS;
  static readonly BILIBILI: string = RuleIds.BILIBILI;
}

export interface RuleItem extends PreferenceItem {
  id: string;
  title: string | Resource;
  summary: string | Resource;
}

@ComponentV2
export struct RulePage {
  @Local ruleStates: Map<string, boolean> = new Map<string, boolean>([
    [RuleId.UTM_PARAMS, true],
    [RuleId.UTM_ENHANCED, false],
    [RuleId.FIREFOX_QUERY_STRIPPING, false],
    [RuleId.BRAVE_CLEAN_URLS, false],
    [RuleId.BRAVE_DEBOUNCE, false],
    [RuleId.BRAVE_QUERY_FILTER, false],
    [RuleId.CLEAR_URLS, false],
    [RuleId.BILIBILI, true],
  ]);
  @Param cloudVersionTime: number = 0;
  @Param braveCleanUrlsVersion: string = '';
  @Param braveDebounceVersion: string = '';
  @Param braveQueryFilterVersion: string = '';
  @Param clearUrlsVersion: string = '';
  @Event onCloudRuleEnabledChange: (id: string, value: boolean) => void = () => {
  };
  private readonly localRuleItems: RuleItem[] = [
    {
      id: RuleId.UTM_PARAMS,
      title: $r('app.string.utm_rule'),
      summary: $r('app.string.utm_rule_desc'),
    },
    {
      id: RuleId.UTM_ENHANCED,
      title: $r('app.string.utm_enhanced_rule'),
      summary: $r('app.string.utm_enhanced_rule_desc'),
    },
  ];
  private readonly cloudRuleItems: RuleItem[] = [
    {
      id: RuleId.FIREFOX_QUERY_STRIPPING,
      title: $r('app.string.firefox_query_stripping_rule'),
      summary: $r('app.string.cloud_rules_not_synced'),
    },
    {
      id: RuleId.BRAVE_CLEAN_URLS,
      title: $r('app.string.brave_clean_urls_rule'),
      summary: $r('app.string.cloud_rules_not_synced'),
    },
    {
      id: RuleId.BRAVE_QUERY_FILTER,
      title: $r('app.string.brave_query_filter_rule'),
      summary: $r('app.string.cloud_rules_not_synced'),
    },
    {
      id: RuleId.BRAVE_DEBOUNCE,
      title: $r('app.string.brave_debounce_rule'),
      summary: $r('app.string.cloud_rules_not_synced'),
    },
    {
      id: RuleId.CLEAR_URLS,
      title: $r('app.string.clear_urls_rule'),
      summary: $r('app.string.cloud_rules_not_synced'),
    },
  ];
  private readonly exceptionalRuleItems: RuleItem[] = [
    {
      id: RuleId.BILIBILI,
      title: $r('app.string.bilibili_rule'),
      summary: $r('app.string.bilibili_rule_desc'),
    },
  ];

  async aboutToAppear(): Promise<void> {
    this.ruleStates = new Map<string, boolean>([
      [RuleId.UTM_PARAMS, PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS, true)],
      [RuleId.UTM_ENHANCED, PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS_ENHANCED, false)],
      [RuleId.FIREFOX_QUERY_STRIPPING, PreferencesHelper.getBoolean(RuleIds.FIREFOX_QUERY_STRIPPING, false)],
      [RuleId.BRAVE_CLEAN_URLS, PreferencesHelper.getBoolean(RuleIds.BRAVE_CLEAN_URLS, false)],
      [RuleId.BRAVE_DEBOUNCE, PreferencesHelper.getBoolean(RuleIds.BRAVE_DEBOUNCE, false)],
      [RuleId.BRAVE_QUERY_FILTER, PreferencesHelper.getBoolean(RuleIds.BRAVE_QUERY_FILTER, false)],
      [RuleId.CLEAR_URLS, PreferencesHelper.getBoolean(RuleIds.CLEAR_URLS, false)],
      [RuleId.BILIBILI, PreferencesHelper.getBoolean(RuleIds.BILIBILI, true)],
    ]);
  }

  isRuleEnabled(id: string): boolean {
    const value = this.ruleStates.get(id);
    return value ?? false;
  }

  setRuleEnabled(id: string, value: boolean): void {
    const next = new Map<string, boolean>(this.ruleStates);
    next.set(id, value);
    this.ruleStates = next;
    PreferencesHelper.setBoolean(id, value);
    if (id === RuleId.FIREFOX_QUERY_STRIPPING ||
      id === RuleId.BRAVE_CLEAN_URLS ||
      id === RuleId.BRAVE_DEBOUNCE ||
      id === RuleId.BRAVE_QUERY_FILTER ||
      id === RuleId.CLEAR_URLS) {
      this.onCloudRuleEnabledChange(id, value);
    }
  }

  getRuleItemSummary(item: RuleItem): string | Resource {
    if (item.id === RuleId.FIREFOX_QUERY_STRIPPING) {
      if (this.cloudVersionTime > 0) {
        return $r('app.string.cloud_rules_version', spacingText(formatTimestamp(this.cloudVersionTime)));
      }
      return $r('app.string.cloud_rules_not_synced');
    }
    if (item.id === RuleId.BRAVE_CLEAN_URLS) {
      return this.braveCleanUrlsVersion.length > 0
        ? $r('app.string.cloud_rules_version', this.braveCleanUrlsVersion.substring(0, 8))
        : $r('app.string.cloud_rules_not_synced');
    }
    if (item.id === RuleId.BRAVE_DEBOUNCE) {
      return this.braveDebounceVersion.length > 0
        ? $r('app.string.cloud_rules_version', this.braveDebounceVersion.substring(0, 8))
        : $r('app.string.cloud_rules_not_synced');
    }
    if (item.id === RuleId.BRAVE_QUERY_FILTER) {
      return this.braveQueryFilterVersion.length > 0
        ? $r('app.string.cloud_rules_version', this.braveQueryFilterVersion.substring(0, 8))
        : $r('app.string.cloud_rules_not_synced');
    }
    if (item.id === RuleId.CLEAR_URLS) {
      return this.clearUrlsVersion.length > 0
        ? $r('app.string.cloud_rules_version', this.clearUrlsVersion.substring(0, 8))
        : $r('app.string.cloud_rules_not_synced');
    }
    return item.summary;
  }

  getRuleSections(): ListGroupSection[] {
    return [
      new ListGroupSection($r('app.string.local_rules_group'), this.localRuleItems),
      new ListGroupSection($r('app.string.cloud_rules_group'), this.cloudRuleItems),
      new ListGroupSection($r('app.string.exceptional_rules_group'), this.exceptionalRuleItems),
    ];
  }

  @Builder
  renderRuleItem(item: PreferenceItem, index: number) {
    SwitchItem({
      title: (item as RuleItem).title,
      summary: this.getRuleItemSummary(item as RuleItem),
      checked: this.isRuleEnabled((item as RuleItem).id),
      onChange: (value: boolean) => {
        this.setRuleEnabled((item as RuleItem).id, value);
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
