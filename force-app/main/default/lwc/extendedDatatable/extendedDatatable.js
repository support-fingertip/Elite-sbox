import LightningDatatable from 'lightning/datatable';
import fileCellTemplate from './fileCell.html';

export default class ExtendedDatatable extends LightningDatatable {
    static customTypes = {
        customCell: {
            template: fileCellTemplate,
            standardCellLayout: true,
            typeAttributes: ['files']
        }
    };
}