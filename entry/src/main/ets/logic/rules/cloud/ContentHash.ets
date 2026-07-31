import { buffer } from '@kit.ArkTS';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

const HEX_CHARS = '0123456789abcdef';

/**
 * 计算输入字符串的 SHA256 十六进制哈希，用作云端规则的版本标识。
 */
export function contentHash(input: string): string {
  const buf = buffer.from(input, 'utf-8');
  const bytes = new Uint8Array(buf.length);
  for (let i = 0; i < buf.length; i++) {
    bytes[i] = buf[i];
  }
  const md = cryptoFramework.createMd('SHA256');
  md.updateSync({ data: bytes });
  const digest = md.digestSync();
  return bytesToHex(digest.data);
}

function bytesToHex(bytes: Uint8Array): string {
  let hex = '';
  for (let i = 0; i < bytes.length; i++) {
    const b = bytes[i];
    hex += HEX_CHARS.charAt((b >> 4) & 0x0f);
    hex += HEX_CHARS.charAt(b & 0x0f);
  }
  return hex;
}
