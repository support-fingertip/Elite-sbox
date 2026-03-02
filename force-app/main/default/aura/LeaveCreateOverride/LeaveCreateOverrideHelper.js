({
    showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "duration": "5000", // 5 seconds
            "mode": "dismissible"
        });
        toastEvent.fire();
    }
})