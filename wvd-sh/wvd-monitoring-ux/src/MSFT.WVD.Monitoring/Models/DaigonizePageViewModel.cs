using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
    public class DaigonizePageViewModel : IPageViewModel
    {

        public DiagonizeQuery DiagonizeQuery {get; set;}
        public List<ManagementActivity> managementActivity { get; set; }
        public List<ConnectionActivity> connectionActivity { get; set; }
        public ActivityType activityType { get; set; }
        public List<FeedActivity> feedActivity { get; set; }
        public RoleAssignment SelectedRole { get; set; }
    }

    public class DiagonizeQuery : IValidatableObject
    {
        [Required]
        public string upn { get; set; }

        public DateTime startDate { get; set; }
        [DataType(DataType.Date)]
        [DisplayFormat(DataFormatString = "{0:MM-dd-yyyy}"
            , ApplyFormatInEditMode = true)]
       // [ValidIntervalDate(ErrorMessage =
        //    "Join Date can not be greater than current date")]
      
        public DateTime endDate { get; set; }
        public ActivityType activityType { get; set; }
        public ActivityOutcome activityOutcome { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {

            int result = DateTime.Compare(endDate,startDate );
            if (result < 0)
            {
                yield return new ValidationResult("start date must be less than the end date!", new[] { "startDate", "endDate" });
            }
           else if (endDate > DateTime.Now)
        {
                yield return new ValidationResult("End Date cannot be greater than current date.", new[] { "startDate", "endDate" });
          }

        }
    }
    //public class DateValidation : ValidationAttribute
    //{
    //    protected override ValidationResult IsValid(DiagonizeQuery value, ValidationContext validationContext)
    //    {
    //        var model = (Models.DiagonizeQuery)validationContext.ObjectInstance;
    //        //DateTime _lastDeliveryDate = Convert.ToDateTime(value);
    //        DateTime EndDate = Convert.ToDateTime(model.endDate);
    //        if (EndDate > DateTime.Now)
    //        {
    //            return new ValidationResult
    //                 ("End Date cannot be greater than current date.");
    //        }
    //        else
    //        {
    //            return ValidationResult.Success;
    //        }
    //    }
    //}


    public class ValidIntervalDate : ValidationAttribute
    {
        protected override ValidationResult
                IsValid(object value, ValidationContext validationContext)
        {
            DateTime _dateJoin = Convert.ToDateTime(value);
            if (_dateJoin < DateTime.Now)
            {
                return ValidationResult.Success;
            }
            else
            {
                return new ValidationResult
                    ("Join date can not be greater than current date.");
            }
        }
    }

    
}
