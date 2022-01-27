import RudderAnalytics from '@expo/rudder-sdk-node';
import os from 'os';
import { v4 as uuidv4 } from 'uuid';

import { EXPO_LOCAL, EXPO_STAGING, EXPO_NO_TELEMETRY } from '../env';
import UserSettings from '../user/UserSettings';

const PLATFORM_TO_ANALYTICS_PLATFORM: { [platform: string]: string } = {
  darwin: 'Mac',
  win32: 'Windows',
  linux: 'Linux',
};

let client: RudderAnalytics | null = null;
let identified = false;
let identifyData: {
  userId: string;
  deviceId: string;
  traits: Record<string, any>;
} | null = null;

function getClient(): RudderAnalytics {
  if (client) {
    return client;
  }

  client = new RudderAnalytics(
    EXPO_STAGING || EXPO_LOCAL ? '1wpX20Da4ltFGSXbPFYUL00Chb7' : '1wpXLFxmujq86etH6G6cc90hPcC',
    'https://cdp.expo.dev/v1/batch',
    {
      flushInterval: 300,
    }
  );

  // Install flush on exit...
  process.on('SIGINT', () => client?.flush?.());
  process.on('SIGTERM', () => client?.flush?.());

  return client;
}

export async function setUserDataAsync(userId: string, traits: Record<string, any>): Promise<void> {
  if (EXPO_NO_TELEMETRY) {
    return;
  }
  const savedDeviceId = await UserSettings.getAsync('analyticsDeviceId', null);
  const deviceId = savedDeviceId ?? uuidv4();
  if (!savedDeviceId) {
    await UserSettings.setAsync('analyticsDeviceId', deviceId);
  }

  identifyData = {
    userId,
    deviceId,
    traits,
  };

  ensureIdentified();
}

export function logEvent(name: string, properties: Record<string, any> = {}): void {
  if (EXPO_NO_TELEMETRY) {
    return;
  }
  ensureIdentified();

  const { userId, deviceId } = identifyData ?? {};
  const commonEventProperties = { source_version: process.env.__EXPO_VERSION, source: 'expo' };

  const identity = { userId: userId ?? undefined, anonymousId: deviceId ?? uuidv4() };
  getClient().track({
    event: name,
    properties: { ...properties, ...commonEventProperties },
    ...identity,
    context: getContext(),
  });
}

function ensureIdentified(): void {
  if (EXPO_NO_TELEMETRY || identified || !identifyData) {
    return;
  }

  getClient().identify({
    userId: identifyData.userId,
    anonymousId: identifyData.deviceId,
    traits: identifyData.traits,
  });
  identified = true;
}

function getContext(): Record<string, any> {
  const platform = PLATFORM_TO_ANALYTICS_PLATFORM[os.platform()] || os.platform();
  return {
    os: { name: platform, version: os.release() },
    device: { type: platform, model: platform },
    app: { name: 'expo', version: process.env.__EXPO_VERSION },
  };
}
