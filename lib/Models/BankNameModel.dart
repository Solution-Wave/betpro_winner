 class BankName {
   String? id;
   String? name;
   String? acTitle;
   String? acNumber;
   String? iconName;
   int? status;
   // int? limits;
   var currentAmount;
   String? category;
   bool value = false;
   String? BankId;

   BankName(
       {this.id,
         this.name,
         this.acTitle,
         this.acNumber,
         this.iconName,
         this.status,
         // this.limits,
         this.currentAmount,
         this.category});

   BankName.fromJson(Map<String, dynamic> json) {
     id = json['id'];
     name = json['name'];
     acTitle = json['ac_title'];
     acNumber = json['ac_number'];
     iconName = json['image'];
     status = json['status'];
     // limits = json['limits'];
     currentAmount = json['current_amount'];
     category = json['category'];
     BankId = json['id'];
   }

   Map<String, dynamic> toJson() {
     final Map<String, dynamic> data = new Map<String, dynamic>();
     data['id'] = this.id;
     data['name'] = this.name;
     data['ac_title'] = this.acTitle;
     data['ac_number'] = this.acNumber;
     data['icon_name'] = this.iconName;
     data['status'] = this.status;
     // data['limits'] = this.limits;
     data['current_amount'] = this.currentAmount;
     data['category'] = this.category;
     data['id']= this.BankId;
     return data;
   }
 }