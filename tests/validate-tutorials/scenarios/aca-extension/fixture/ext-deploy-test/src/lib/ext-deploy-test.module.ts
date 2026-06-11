import { NgModule, APP_INITIALIZER } from '@angular/core';
import { ExtensionService, provideExtensionConfig } from '@alfresco/adf-extensions';
import { provideEffects } from '@ngrx/effects';
import { ScPageComponent } from './components/page/page.component';
import { ScSidebarComponent } from './components/sidebar/sidebar.component';
import { ScEffects } from './store/sc.effects';

export function provideScExtension() {
  return [
    provideExtensionConfig(['ext-deploy-test.plugin.json']),
    provideEffects(ScEffects),
    {
      provide: APP_INITIALIZER,
      multi: true,
      useFactory: (ext: ExtensionService) => () => ext.setComponents({
        'sc.components.page': ScPageComponent,
        'sc.components.sidebar': ScSidebarComponent
      }),
      deps: [ExtensionService]
    }
  ];
}

@NgModule({})
export class ScExtensionModule {}
