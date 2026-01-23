public class UpdateUsersQueueable implements Queueable {
    private List<User> usersToUpdate;

    public UpdateUsersQueueable(List<User> users) {
        this.usersToUpdate = users;
    }

    public void execute(QueueableContext context) {
        update usersToUpdate;
    }
}