import { Injectable } from '@angular/core';
import { AppConfigService } from '@alfresco/adf-core';

@Injectable({ providedIn: 'root' })
export class ScService {
  constructor(private appConfig: AppConfigService) {}
  get baseUrl(): string { return this.appConfig.get<string>('plugins.scService.baseUrl'); }
}
