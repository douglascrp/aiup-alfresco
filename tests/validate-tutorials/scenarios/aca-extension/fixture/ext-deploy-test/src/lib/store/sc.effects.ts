import { Injectable } from '@angular/core';
import { Actions, createEffect, ofType } from '@ngrx/effects';
import { tap } from 'rxjs/operators';
import { scRefresh } from './sc.actions';

@Injectable()
export class ScEffects {
  constructor(private actions$: Actions) {}
  refresh$ = createEffect(() => this.actions$.pipe(
    ofType(scRefresh),
    tap(() => {})
  ), { dispatch: false });
}
