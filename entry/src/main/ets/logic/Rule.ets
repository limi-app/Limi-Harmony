import { RuleConfig } from '../data/rules/RuleConfig';
import { processUTMParams } from './rules/common/UTMParams';
import { processUTMParamsEnhanced } from './rules/common/UTMParamsEnhanced';
import { getBilibiliRedirectTargetHost, processBilibiliRedirectUrl } from './rules/bilibili/BilibiliRedirects';
import { isBilibiliNoParamsTarget, processBilibiliNoParamsUrl } from './rules/bilibili/BilibiliNoParams';
import {
  getCachedQueryStripping,
  getCachedCleanUrlsRules,
  getCachedDebounceRules,
  getCachedQueryFilterRules,
} from './rules/cloud/CloudRuleRepository';
import { processQueryStripping } from './rules/cloud/firefox/QueryStripping';
import { processCleanUrls } from './rules/cloud/brave/CleanUrls';
import { processDebounce } from './rules/cloud/brave/Debounce';
import { processQueryFilter } from './rules/cloud/brave/QueryFilter';
import { extractUrlList, ParsedUrl, parseUrl } from '../utils/LinkExtractor';
import { PreferencesHelper } from '../utils/PreferencesHelper';

export class RuleIds {
  static readonly BILIBILI: string = 'bilibili_rules';
  static readonly UTM_PARAMS: string = 'utm_params_rules';
  static readonly UTM_PARAMS_ENHANCED: string = 'utm_params_enhanced_rules';
  static readonly FIREFOX_QUERY_STRIPPING: string = 'firefox_query_stripping_rules';
  static readonly BRAVE_CLEAN_URLS: string = 'brave_clean_urls_rules';
  static readonly BRAVE_DEBOUNCE: string = 'brave_debounce_rules';
  static readonly BRAVE_QUERY_FILTER: string = 'brave_query_filter_rules';
  static readonly INCOGNITO_MODE: string = 'incognito_mode';
}

export async function processUrl(urlString: string): Promise<string> {
  const ruleConfig = new RuleConfig();
  ruleConfig.UTMParams = PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS, true);
  ruleConfig.UTMParamsEnhanced = PreferencesHelper.getBoolean(RuleIds.UTM_PARAMS_ENHANCED, false);
  ruleConfig.bilibili = PreferencesHelper.getBoolean(RuleIds.BILIBILI, true);
  ruleConfig.firefoxQueryStripping = PreferencesHelper.getBoolean(RuleIds.FIREFOX_QUERY_STRIPPING, false);
  ruleConfig.braveCleanUrls = PreferencesHelper.getBoolean(RuleIds.BRAVE_CLEAN_URLS, false);
  ruleConfig.braveDebounce = PreferencesHelper.getBoolean(RuleIds.BRAVE_DEBOUNCE, false);
  ruleConfig.braveQueryFilter = PreferencesHelper.getBoolean(RuleIds.BRAVE_QUERY_FILTER, false);

  let finalUrl = urlString;

  // 第一层：去重定向跳转（Brave Debounce）
  if (ruleConfig.braveDebounce) {
    const rules = getCachedDebounceRules();
    if (rules.length > 0) {
      const target = processDebounce(finalUrl, rules);
      if (target !== null) {
        finalUrl = target;
      }
    }
  }

  // 第二层：特定 Host 匹配处理
  const parsed: ParsedUrl | null = parseUrl(finalUrl);
  if (parsed !== null) {
    const host = parsed.host.toLowerCase();

    if (ruleConfig.bilibili && isInHostList(host, getBilibiliRedirectTargetHost())) {
      finalUrl = await processBilibiliRedirectUrl(finalUrl);
    } else if (ruleConfig.bilibili && isBilibiliNoParamsTarget(host)) {
      finalUrl = processBilibiliNoParamsUrl(finalUrl);
    }
  }

  // 第三层：通用参数去除处理
  if (ruleConfig.UTMParams) {
    finalUrl = processUTMParams(finalUrl);
  }
  if (ruleConfig.UTMParamsEnhanced) {
    finalUrl = processUTMParamsEnhanced(finalUrl);
  }
  if (ruleConfig.firefoxQueryStripping) {
    const cloudData = getCachedQueryStripping();
    if (cloudData.stripList.length > 0) {
      finalUrl = processQueryStripping(finalUrl, cloudData.stripList, cloudData.allowList);
    }
  }
  if (ruleConfig.braveCleanUrls) {
    const rules = getCachedCleanUrlsRules();
    if (rules.length > 0) {
      finalUrl = processCleanUrls(finalUrl, rules);
    }
  }
  if (ruleConfig.braveQueryFilter) {
    const rules = getCachedQueryFilterRules();
    if (rules.length > 0) {
      finalUrl = processQueryFilter(finalUrl, rules);
    }
  }

  if (finalUrl.length === 0) {
    return urlString;
  }
  return finalUrl;
}

function isInHostList(host: string, hosts: string[]): boolean {
  for (let i = 0; i < hosts.length; i++) {
    if (host === hosts[i].toLowerCase()) {
      return true;
    }
  }
  return false;
}

export interface ProcessLinksResult {
  processedText: string;
  processedUrlList: string[];
  isEmpty: boolean;
  isNotHasUrls: boolean;
}

export async function processLinksInText(text: string): Promise<ProcessLinksResult> {
  if (text.length === 0) {
    return {
      processedText: '',
      processedUrlList: [],
      isEmpty: true,
      isNotHasUrls: false
    };
  }

  const urls = extractUrlList(text, true, false);
  if (urls.length === 0) {
    return {
      processedText: text,
      processedUrlList: [],
      isEmpty: false,
      isNotHasUrls: true
    };
  }

  const processedUrlList: string[] = [];
  let resultText = text;
  for (let i = 0; i < urls.length; i++) {
    const processed = await processUrl(urls[i]);
    processedUrlList.push(processed);
    resultText = resultText.replaceAll(urls[i], processed);
  }
  return {
    processedText: resultText,
    processedUrlList: processedUrlList,
    isEmpty: false,
    isNotHasUrls: false
  };
}
