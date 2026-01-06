import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subscription, timer } from 'rxjs';
import { ModalService, ModalState } from './modal.service';

@Component({
  selector: 'app-shared-modal',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="modal fade show" tabindex="-1" *ngIf="state.visible" style="display:block; background: rgba(0,0,0,0.4);">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">{{ state.title }}</h5>
            <button type="button" class="btn-close" aria-label="Close" (click)="onClose()"></button>
          </div>
          <div class="modal-body">
            <p [innerText]="state.message"></p>
          </div>
          <div class="modal-footer" *ngIf="state.type === 'confirm'">
            <button type="button" class="btn btn-secondary" (click)="onConfirm(false)">No</button>
            <button type="button" class="btn btn-primary" (click)="onConfirm(true)">Yes</button>
          </div>
          <div class="modal-footer" *ngIf="state.type === 'alert'">
            <button type="button" class="btn btn-primary" (click)="onClose()">OK</button>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: []
})
export class SharedModalComponent implements OnInit, OnDestroy {
  state: ModalState = { visible: false, type: null };
  sub?: Subscription;
  autoCloseSub?: Subscription;

  constructor(private modal: ModalService) {}

  ngOnInit(): void {
    this.sub = this.modal.stateChanges.subscribe(s => {
      this.state = s;
      if (this.autoCloseSub) {
        this.autoCloseSub.unsubscribe();
        this.autoCloseSub = undefined;
      }
      if (s.visible && s.type === 'alert' && s.autoCloseMs) {
        this.autoCloseSub = timer(s.autoCloseMs).subscribe(() => this.onClose());
      }
    });
  }

  ngOnDestroy(): void {
    this.sub?.unsubscribe();
    this.autoCloseSub?.unsubscribe();
  }

  onConfirm(value: boolean) {
    this.modal.resolveConfirm(value);
  }

  onClose() {
    this.modal.close();
  }
}
