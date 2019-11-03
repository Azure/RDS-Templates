using MSFT.WVD.Diagnostics.Common.Models;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MSFT.WVD.Diagnostics.Models
{
    public class DiagonizePageViewModel : IPageViewModel
    {
        public DiagonizeQuery DiagonizeQuery { get; set; }
        public List<ManagementActivity> ManagementActivity { get; set; }
        public List<ConnectionActivity> ConnectionActivity { get; set; }
        public ActivityType ActivityType { get; set; }
        public startDateEnum startDateEnum { get; set; }
        public List<FeedActivity> FeedActivity { get; set; }
        public RoleAssignment SelectedRole { get; set; }
        public bool isExisting { get; set; }
    }
  
    public class DiagonizeQuery : IValidatableObject
    {
        [Required]
        public string UPN { get; set; }
        [DataType(DataType.Date)]
        [DisplayFormat(DataFormatString =
            "{0:yyyy-MM-dd}", ApplyFormatInEditMode = true)]
        public DateTime StartDate { get; set; }
        [DataType(DataType.Date)]
        [DisplayFormat(DataFormatString =
            "{0:yyyy-MM-dd}", ApplyFormatInEditMode = true)]
        public DateTime EndDate { get; set; }
        public ActivityType ActivityType { get; set; }
        public startDateEnum startDateEnum { get; set; }
        public ActivityOutcome ActivityOutcome { get; set; }
        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            int result = DateTime.Compare(EndDate, StartDate);
            if (result < 0)
            {
                yield return new ValidationResult("From date must be less than to date!", new[] { "StartDate", "EndDate" });
            }
            else if (EndDate > DateTime.Now)
            {
                yield return new ValidationResult("To date cannot be greater than current date.", new[] { "StartDate", "EndDate" });
            }
            else if (EndDate > StartDate.AddDays(+2))
            {
                yield return new ValidationResult("Difference between from date and to date should not be greater than 48hours", new[] { "StartDate", "EndDate" });

            }
        }
    }

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
