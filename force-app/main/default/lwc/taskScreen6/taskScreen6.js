import { LightningElement,track,api } from 'lwc';
import saveTask from '@salesforce/apex/beatPlannerlwc.saveTask';
import getTaskData from '@salesforce/apex/beatPlannerlwc.getTaskData';
import deleteTask from '@salesforce/apex/beatPlannerlwc.deleteTask';
import updateTask from '@salesforce/apex/beatPlannerlwc.updateTask';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';

export default class TaskScreen6 extends LightningElement {
    @track tasks = [];
    @track originalTasks = [];
    isModalOpen = false;
    modalTitle = '';
    selectedTaskId = '';
    selectedTaskIndex = '';
    taskId = '';
    taskName = '';
    taskDate = '';
    taskStatus = '';
    description = '';
    isLoading = false;
    isDeleteModalOpen = false; 
    @track statusOptions = [
        { label: 'Not Started', value: 'Not Started' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Completed', value: 'Completed' }
    ];
    isDescriptionPopup = false;
    @api objectId;
    @api isDesktop;
    previousCheckedState ='';
    containerClass;

    // Getter methods for task counts
    get notStartedCount() {
        return this.tasks.filter(task => task.status === 'Not Started').length;
    }
    get inProgressCount() {
        return this.tasks.filter(task => task.status === 'In Progress').length;
    }
    get completedCount() {
        return this.tasks.filter(task => task.status === 'Completed').length;
    }

    //on loading this method will be called
    connectedCallback() {
        console.log('objectId'+this.objectId);
        this.fetchTasks();
        this.containerClass = this.isDesktop ? 'slds-modal__container ' : '';
    }

    //fetching Tasks
    fetchTasks() {
        this.isLoading = true;
        getTaskData({ objectId: this.objectId})
            .then((result) => {
                console.log(result);
                this.tasks = result;
                this.updateTaskClasses();
                this.originalTasks = result;
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                this.showToast('Error', 'Error fetching tasks: ' + error.body.message, 'error');
            });
    }

    // Update task classes based on their status
    updateTaskClasses() {
        this.tasks = this.tasks.map(task => {
            let taskClass = '';
            if (task.status === 'Not Started' || task.status === 'In Progress'){
                taskClass = 'not-started-icon';
            }else if (task.status === 'Completed') {
                taskClass = 'completed-icon';
            }
            return { ...task, class: taskClass };
        });
    }
    
    //When Toggle Clicked
    toggleChangeHandler(event){
        event.stopPropagation(); 
        this.isDescriptionPopup = true;
        const itemId = event.currentTarget.dataset.id;
        const taskIndex = parseInt(event.currentTarget.dataset.index, 10);
        this.selectedTaskId = itemId;
        this.selectedTaskIndex=taskIndex;
        this.previousCheckedState = this.tasks[taskIndex].checked;
        // Update task checked state
        this.tasks = this.tasks.map((task, i) =>
            i == taskIndex ? { ...task, checked: event.target.checked, classtoggle: event.target.checked ? 'toggle' : '' } : task
        );

        const task = this.tasks.find(task => task.id == itemId);
        this.taskName = task.name;
        this.taskStatus = event.target.checked ? 'Completed' : 'Not Started',
        this.description = task.description;
        this.taskId = itemId;
    }

    //When Input changed
    handleInputChange(event) {
        const field = event.currentTarget.dataset.id;
        if (field === 'taskName') {
            this.taskName = event.currentTarget.value;
        }
        else if (field === 'description') {
            this.description = event.currentTarget.value;
        }
    }

    //save Status and Description
    updateTask() {
        if(this.description == '' || this.description == undefined)
        {
            this.showToast('Error', 'Please enter description', 'Error');
            return;
        }
        this.isLoading = true;
        this.isDescriptionPopup = false;
        const fields = {
            Id: this.taskId,
            Description__c: this.description,
            Task_Status__c: this.taskStatus
        };
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.tasks = this.tasks.map(task => 
                    task.id === this.taskId ? { ...task, description: this.description, status: this.taskStatus } : task
                );
                this.updateTaskClasses();
                this.resetForm();
                this.isLoading = false;
                this.showToast('Success', 'Task status updated successfully', 'success');
    
            })
            .catch(error => {
                console.error('Error updating task:', error);
                this.showToast('Success', 'Task status updated successfully', 'success');
            });
    }


    saveTask() {

        if(this.description == '')
        {
            this.showToast('Error', 'Please enter description', 'Error');
            return;
        }


        this.isLoading = true;
        this.isModalOpen = false;
        this.isDescriptionPopup = false;
        console.log('this.taskDate'+this.taskDate);
        saveTask({ taskId: this.taskId, 
                taskName: this.taskName,
                taskDate: this.taskDate,
                taskStatus: this.taskStatus,
                description:this.description,
                objectId:this.objectId,
             })
            .then((result) => {
                // Update the task in the local tasks list (either create or update)
            
                console.log(result);
                this.tasks = result.map((task) => ({
                    ...task,
                    icon: 'action:approval',
                    checked: task.status === 'Completed' ? true : false,
                }));
                this.updateTaskClasses();
                this.originalTasks = this.tasks;
                this.resetForm();
                this.showToast('Success', 'Task status updated successfully', 'success');
           
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                console.log('error'+error.body.message);
                this.showToast('Error', 'Error saving task: ' + error.body.message, 'error');
            });
    }

    closeModal() {
        this.isModalOpen = false;
        this.isDescriptionPopup = false;
    
        if (this.selectedTaskIndex !== undefined && this.selectedTaskIndex !== null) {
            // Restore the previous checked state
            this.tasks = this.tasks.map((task, i) => 
                i == this.selectedTaskIndex ? { ...task, checked: this.previousCheckedState,classtoggle: this.previousCheckedState ? 'toggle' : '' } : task
            );
        }
    
        this.resetForm();
    }
    

    resetForm() {
        this.taskName = '';
        this.taskDate = '';
        this.taskStatus = 'Not Started';
        this.taskId = '';
        this.description=''; 

    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
 
}