define(["jquery"], // Require jquery
       function($){

        //transform serializeArray to JSON format
        $.fn.serializeObject = function()
        {
            var o = {};
            var a = this.serializeArray();
            
            /* Because serializeArray() ignores unset checkboxes and radio buttons: */
            a = a.concat(
                $('#form-quidd input[type=checkbox]:not(:checked)').map(
                    function() {
                        return {"name": this.name, "value": this.value}
                    }).get()
            );
            $.each(a, function() {
                if (o[this.name] !== undefined) {
                    if (!o[this.name].push) {
                        o[this.name] = [o[this.name]];
                    }
                    o[this.name].push(this.value || '');
                } else {
                    o[this.name] = this.value || '';
                }
            });
            return o;
        };

        //close lightbox
        $(document).on("click", "#close, #bgLightbox", function(){
            $("#lightBox, #bgLightbox").fadeOut(200);
        });

        //define tooltip global with jquery UI
        // $(document).tooltip({
        //     track: true,
        //     content: function() {
        //         var element = $(this);
        //         return element.attr("title");
                
        //     }
        // });
});


