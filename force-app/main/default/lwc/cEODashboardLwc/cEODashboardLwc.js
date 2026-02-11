import { LightningElement, track } from 'lwc';

export default class cEODashboardLwc extends LightningElement {
 fromDate;
    toDate;
    salesChannel;
    rsm;
    asm;

    salesChannelOptions = [
        { label: "All", value: "all" },
        { label: "GT", value: "gt" },
        { label: "MT", value: "mt" }
    ];

    rsmOptions = [
        { label: "All", value: "all" },
        { label: "RSM 1", value: "r1" },
        { label: "RSM 2", value: "r2" }
    ];

    asmOptions = [
        { label: "All", value: "all" },
        { label: "ASM 1", value: "a1" },
        { label: "ASM 2", value: "a2" }
    ];

    // STATIC dummy dashboard numbers
    @track cards = [
        { id: 1, title: "Active Outlet Count", value: "120" },
        { id: 2, title: "Activation Pending Outlets", value: "15" },

        { id: 3, title: "PJP Outlets", value: "80" },
        { id: 4, title: "PJP Productive Outlets", value: "45" },
        { id: 5, title: "PJP Outlets Visited %", value: "56%" },
        { id: 6, title: "PJP Productive Outlets %", value: "42%" },

        { id: 7, title: "Non-PJP Outlets", value: "60" },
        { id: 8, title: "Non-PJP Productive Outlets", value: "22" },
        { id: 9, title: "Non-PJP Outlets Visited %", value: "38%" },
        { id: 10, title: "Non-PJP Productive Outlets %", value: "29%" },

        { id: 11, title: "PJP Calls", value: "140" },
        { id: 12, title: "PJP Productive Calls", value: "84" },
        { id: 13, title: "PJP Productive Calls %", value: "60%" },

        { id: 14, title: "Non-PJP Calls", value: "110" },
        { id: 15, title: "Non-PJP Productive Calls", value: "44" },
        { id: 16, title: "Non-PJP Productive Calls %", value: "40%" },

        { id: 17, title: "Total Calls", value: "250" },
        { id: 18, title: "Total Productive Calls", value: "128" },
        { id: 19, title: "Total Productive Calls %", value: "51%" }
    ];

    handleChange(event) {
        console.log("Filter updated:", event.target.label, event.target.value);
    }

    handleRefresh() {
        console.log("Dashboard refreshed.");
    }
}