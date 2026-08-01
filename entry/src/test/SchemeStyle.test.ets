import { describe, expect, it } from '@ohos/hypium';
import {
  hasUrlScheme,
  ensureUrlScheme,
  applyOriginalSchemeStyle,
} from '../main/ets/logic/Rule';
import { processUTMParams } from '../main/ets/logic/rules/common/UTMParams';

export default function schemeStyleTest() {
  describe('SchemeStyleTest', () => {

    // ── hasUrlScheme ──────────────────────────────────────────────────

    it('hasSchemeHttp', 0, () => {
      expect(hasUrlScheme('http://example.com')).assertTrue();
    });

    it('hasSchemeHttps', 0, () => {
      expect(hasUrlScheme('https://example.com')).assertTrue();
    });

    it('hasSchemeMailto', 0, () => {
      expect(hasUrlScheme('mailto:user@example.com')).assertTrue();
    });

    it('hasSchemeFtp', 0, () => {
      expect(hasUrlScheme('ftp://ftp.example.com')).assertTrue();
    });

    it('noSchemeBareDomain', 0, () => {
      expect(hasUrlScheme('a.com')).assertFalse();
    });

    it('noSchemeWithPath', 0, () => {
      expect(hasUrlScheme('b23.tv/DxrYn0F')).assertFalse();
    });

    it('noSchemeEmail', 0, () => {
      expect(hasUrlScheme('e@a.com')).assertFalse();
    });

    it('noSchemeWithQuery', 0, () => {
      expect(hasUrlScheme('a.com?utm_source=x')).assertFalse();
    });

    it('noSchemeHostWithPort', 0, () => {
      // host:port 不应被误判为 scheme
      expect(hasUrlScheme('a.com:8080')).assertFalse();
      expect(hasUrlScheme('localhost:3000')).assertFalse();
      expect(hasUrlScheme('intranet:8080')).assertFalse();
      expect(hasUrlScheme('gitlab:3000')).assertFalse();
    });

    it('hasSchemeCustomDeepLink', 0, () => {
      // 自定义深度链接 scheme 应被识别
      expect(hasUrlScheme('taobao://item.htm?id=1')).assertTrue();
      expect(hasUrlScheme('myapp:deep/path')).assertTrue();
      expect(hasUrlScheme('wechat://profile')).assertTrue();
    });

    it('hasSchemeTel', 0, () => {
      expect(hasUrlScheme('tel:+8613800138000')).assertTrue();
    });

    it('hasSchemeData', 0, () => {
      expect(hasUrlScheme('data:text/plain,hello')).assertTrue();
    });

    // ── ensureUrlScheme ───────────────────────────────────────────────

    it('ensureSchemeAddsHttp', 0, () => {
      expect(ensureUrlScheme('a.com')).assertEqual('http://a.com');
    });

    it('ensureSchemeKeepsHttp', 0, () => {
      expect(ensureUrlScheme('http://a.com')).assertEqual('http://a.com');
    });

    it('ensureSchemeKeepsHttps', 0, () => {
      expect(ensureUrlScheme('https://a.com')).assertEqual('https://a.com');
    });

    it('ensureSchemeKeepsMailto', 0, () => {
      expect(ensureUrlScheme('mailto:user@example.com')).assertEqual('mailto:user@example.com');
    });

    it('ensureSchemeAddsHttpToB23tv', 0, () => {
      expect(ensureUrlScheme('b23.tv/DxrYn0F')).assertEqual('http://b23.tv/DxrYn0F');
    });

    it('ensureSchemeKeepsCustomDeepLink', 0, () => {
      expect(ensureUrlScheme('taobao://item.htm?id=1')).assertEqual('taobao://item.htm?id=1');
      expect(ensureUrlScheme('myapp:deep/path')).assertEqual('myapp:deep/path');
    });

    it('ensureSchemeKeepsTel', 0, () => {
      expect(ensureUrlScheme('tel:+8613800138000')).assertEqual('tel:+8613800138000');
    });

    // ── applyOriginalSchemeStyle ──────────────────────────────────────

    it('stripHttpWhenNoOriginalScheme', 0, () => {
      expect(applyOriginalSchemeStyle('http://a.com', false)).assertEqual('a.com');
    });

    it('stripHttpsWhenNoOriginalScheme', 0, () => {
      expect(applyOriginalSchemeStyle('https://www.bilibili.com/video/BV1', false))
        .assertEqual('www.bilibili.com/video/BV1');
    });

    it('keepHttpWhenOriginalHadScheme', 0, () => {
      expect(applyOriginalSchemeStyle('http://a.com', true)).assertEqual('http://a.com');
    });

    it('keepHttpsWhenOriginalHadScheme', 0, () => {
      expect(applyOriginalSchemeStyle('https://a.com', true)).assertEqual('https://a.com');
    });

    // ── 集成：UTM 处理 + scheme 原样式 ────────────────────────────────

    it('protocolLessUrlWithUtmProcessedNoSchemeAdded', 0, () => {
      // 模拟 processUrl 的 scheme 补全/还原逻辑 + UTM 处理
      const input = 'a.com?utm_source=x&keep=1';
      const hadScheme = hasUrlScheme(input);
      const ensured = ensureUrlScheme(input);
      const processed = processUTMParams(ensured);
      const result = applyOriginalSchemeStyle(processed, hadScheme);
      expect(result).assertEqual('a.com?keep=1');
    });

    it('protocolLessUrlNoParamsStaysUnchanged', 0, () => {
      const input = 'e@a.com';
      const hadScheme = hasUrlScheme(input);
      const ensured = ensureUrlScheme(input);
      const processed = processUTMParams(ensured);
      const result = applyOriginalSchemeStyle(processed, hadScheme);
      expect(result).assertEqual('e@a.com');
    });

    it('urlWithSchemeProcessedAndKept', 0, () => {
      const input = 'https://example.com?utm_source=x&keep=1';
      const hadScheme = hasUrlScheme(input);
      const ensured = ensureUrlScheme(input);
      const processed = processUTMParams(ensured);
      const result = applyOriginalSchemeStyle(processed, hadScheme);
      expect(result).assertEqual('https://example.com?keep=1');
    });

    it('b23tvGetsHttpSchemeForRedirect', 0, () => {
      // b23.tv/DxrYn0F 需要 http:// 前缀才能发起 HTTP 重定向请求
      const input = 'b23.tv/DxrYn0F';
      const hadScheme = hasUrlScheme(input);
      const ensured = ensureUrlScheme(input);
      expect(ensured).assertEqual('http://b23.tv/DxrYn0F');
      expect(hadScheme).assertFalse();
      // 重定向目标 https://www.bilibili.com/... 也去掉协议头，保持无协议样式
      const redirectTarget = 'https://www.bilibili.com/video/BV1xxx';
      const result = applyOriginalSchemeStyle(redirectTarget, hadScheme);
      expect(result).assertEqual('www.bilibili.com/video/BV1xxx');
    });
  });
}
