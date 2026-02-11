import { LightningElement, track } from 'lwc';
import getQueryTemplates from '@salesforce/apex/ClientInspectorController.getQueryTemplates';
import getCountForSoql from '@salesforce/apex/ClientInspectorController.getCountForSoql';
import fetchBatch from '@salesforce/apex/ClientInspectorController.fetchBatch';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ClientInspector extends LightningElement {
  @track templates = [];
  @track templateOptions = [];
  selectedTemplateId = '';
  @track totalCount = 0;
  @track fetchedCount = 0;
  @track fetchedData = []; // array of row objects
  datatableColumns = [];
  datatableData = [];
  isLoadingBatch = false;
  loadingCount = false;
  totalCountKnown = false;
  stopped = false;
  batchSize = 200; // consistent with Apex MAX_BATCH_SIZE

  // internal
  currentOffset = 0;

  connectedCallback() {
    this.loadTemplates();
  }

  async loadTemplates() {
    try {
      const res = await getQueryTemplates();
      this.templates = res;
      this.templateOptions = res.map(r => ({ label: r.Name, value: r.Id }));
    } catch (err) {
      this.showToast('Error', 'Failed to load templates: ' + this.getErrorMessage(err), 'error');
    }
  }

  handleTemplateChange(e) {
    this.selectedTemplateId = e.detail.value;
  }

  async handleRun() {
    if (!this.selectedTemplateId) {
      this.showToast('Warning', 'Please select a dataset first', 'warning');
      return;
    }
    // reset
    this.fetchedData = [];
    this.datatableData = [];
    this.datatableColumns = [];
    this.totalCount = 0;
    this.fetchedCount = 0;
    this.currentOffset = 0;
    this.stopped = false;
    this.totalCountKnown = false;

    // get count
    try {
      this.loadingCount = true;
      const count = await getCountForSoql({ templateId: this.selectedTemplateId });
      this.totalCount = count;
      this.totalCountKnown = true;
      this.loadingCount = false;
      //this.showToast('Info', 'Found ' + count + ' records', 'info');
      if (count === 0) return;
      // start auto-load
      this.loadAllBatches();
    } catch (err) {
      this.loadingCount = false;
      this.showToast('Error', 'Count failed: ' + this.getErrorMessage(err), 'error');
    }
  }

  async loadAllBatches() {
    this.isLoadingBatch = true;
    while (!this.stopped && this.fetchedCount < this.totalCount) {
      try {
        const resp = await fetchBatch({
          templateId: this.selectedTemplateId,
          limitSize: this.batchSize,
          offset: this.currentOffset
        });
        const records = resp.records || [];
        const fields = resp.fields || [];
        // If first batch, construct columns
        if (this.fetchedCount === 0) {
          this.buildColumns(fields, records);
        }
        // append records
        for (let r of records) {
          this.fetchedData.push(r);
        }
        this.fetchedCount = this.fetchedData.length;
        this.datatableData = this.fetchedData.slice(); // shallow copy to trigger rerender
        // increment offset
        this.currentOffset += records.length;
        // safety: if zero returned, break to avoid infinite loop
        if (!records || records.length === 0) break;
        // micro pause to allow UI update
        await this.sleep(150);
      } catch (err) {
        this.showToast('Error', 'Batch fetch failed: ' + this.getErrorMessage(err), 'error');
        break;
      }
    }
    this.isLoadingBatch = false;
    if (this.stopped) {
      //this.showToast('Info', 'Loading stopped by user. Fetched ' + this.fetchedCount + ' of ' + this.totalCount, 'info');
    } else {
      //this.showToast('Success', 'Finished loading all available records (' + this.fetchedCount + ')', 'success');
    }
  }

  handleStop() {
    this.stopped = true;
    this.isLoadingBatch = false;
  }

  handleClear() {
    this.selectedTemplateId = '';
    this.fetchedData = [];
    this.datatableData = [];
    this.datatableColumns = [];
    this.totalCount = 0;
    this.fetchedCount = 0;
    this.currentOffset = 0;
    this.stopped = false;
    this.totalCountKnown = false;
  }

  buildColumns(fields, sampleRecords) {
    // fields = list of tokens from SELECT clause; may be simple 'Id', 'Name', 'Account.Name' or 'COUNT(Id) as ct' etc.
    const columns = [];
    let seen = new Set();
    for (let f of fields) {
      let key = this.normalizeFieldKey(f);
      if (seen.has(key)) continue;
      seen.add(key);
      // determine label
      let label = key.replace(/__/g, '').replace(/\./g, ' ');

      columns.push({
        label: label,
        fieldName: key,
        type: 'text',
        sortable: false
      });
    }
    // ensure Id present as key-field
    if (!seen.has('Id')) {
      columns.unshift({ label: 'Id', fieldName: 'Id', type: 'text' });
    }
    this.datatableColumns = columns;
  }

  normalizeFieldKey(fieldToken) {
    let t = String(fieldToken).trim();
    // handle "as" alias
    const asRegex = /\s+as\s+/i;
    if (asRegex.test(t)) {
      const parts = t.split(asRegex);
      if (parts.length > 1) return parts[1].replace(/['"]/g, '').trim();
    }
    // handle relationship: keep last part
    if (t.indexOf('.') !== -1) {
      const arr = t.split('.');
      return arr[arr.length - 1].trim();
    }
    // remove parentheses crudely
    t = t.replace(/[()]/g, '');
    return t;
  }

  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  get hasData() {
    return this.datatableData && this.datatableData.length > 0;
  }

  get isStopped() {
    // Stop button should be enabled when loading; otherwise disabled
    return !this.isLoadingBatch;
  }

  downloadCsv() {
    if (!this.fetchedData || this.fetchedData.length === 0) {
      this.showToast('Warning', 'No data to download', 'warning');
      return;
    }
    // build CSV
    const cols = this.datatableColumns.map(c => c.fieldName);
    const header = this.datatableColumns.map(c => '"' + c.label.replace(/"/g, '""') + '"').join(',');
    const rows = this.fetchedData.map(r => {
      return cols.map(col => {
        let v = r[col];
        if (v === null || v === undefined) return '""';
        // stringify object values (dates / numbers)
        let s = String(v);
        s = s.replace(/"/g, '""');
        return '"' + s + '"';
      }).join(',');
    });
    const csvContent = [header].concat(rows).join('\r\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'inspector_export.csv';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  getErrorMessage(err) {
    if (!err) return '';
    if (typeof err === 'string') return err;
    if (err.body && err.body.message) return err.body.message;
    if (err.message) return err.message;
    return JSON.stringify(err);
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    }));
  }
}