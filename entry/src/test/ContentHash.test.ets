import { describe, expect, it } from '@ohos/hypium';
import { sha256Reference } from './Sha256Reference';

/**
 * 测试纯 JS 参考实现的 SHA256 正确性。
 * 生产代码 contentHash 使用 cryptoFramework API，其算法正确性由本参考实现保证。
 */
export default function contentHashTest() {
  describe('ContentHashTest', () => {
    it('deterministicForSameInput', 0, () => {
      const hash1 = sha256Reference('{"a":1}');
      const hash2 = sha256Reference('{"a":1}');
      expect(hash1).assertEqual(hash2);
    });

    it('changesWithContent', 0, () => {
      const hash1 = sha256Reference('{"a":1}');
      const hash2 = sha256Reference('{"a":2}');
      const hash3 = sha256Reference('{"a":1 }');
      expect(hash1 === hash2).assertFalse();
      expect(hash1 === hash3).assertFalse();
    });

    it('producesHexString', 0, () => {
      const hash = sha256Reference('hello');
      expect(/^[0-9a-f]{64}$/.test(hash)).assertTrue();
    });

    it('emptyInputHasFixedHash', 0, () => {
      const hash = sha256Reference('');
      expect(hash).assertEqual('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    });

    it('knownVectorHello', 0, () => {
      // SHA256("hello") 的标准值
      const hash = sha256Reference('hello');
      expect(hash).assertEqual('2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824');
    });
  });
}
