import { deviceInfo } from '@kit.BasicServicesKit';
import { uiMaterial } from '@kit.ArkUI';

const UI_MATERIAL_MIN_API: number = 26;

export function uiMaterialSupported(): boolean {
  return deviceInfo.sdkApiVersion >= UI_MATERIAL_MIN_API;
}

export function immersiveStateEnabled(): boolean {
  if (!uiMaterialSupported()) {
    return false;
  }
  return uiMaterial.getMaterialInfo().state !== uiMaterial.MaterialState.DISABLE;
}

export function createSheetMaterial(): uiMaterial.Material {
  const options: uiMaterial.ImmersiveOptions = {
    style: uiMaterial.ImmersiveStyle.ULTRA_THICK
  };
  return new uiMaterial.ImmersiveMaterial(options);
}

export function createToggleMaterial(): uiMaterial.Material {
  const options: uiMaterial.ImmersiveOptions = {
    interactive: true,
    lightEffect: { color: Color.White }
  };
  return new uiMaterial.ImmersiveMaterial(options);
}

// 官方"沉浸光感生效范围外"的替代方案：backgroundEffect 玻璃效果（API 11+，不受 26 生效范围约束）
export function glassEffect(): BackgroundEffectOptions {
  const options: BackgroundEffectOptions = {
    radius: 24,
    saturation: 1.25,
    brightness: 1.08,
    color: '#20FFFFFF',
    adaptiveColor: AdaptiveColor.AVERAGE
  };
  return options;
}
