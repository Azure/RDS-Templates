import { Pipe } from '@angular/core';
import { PipeTransform } from '@angular/core';
@Pipe({
    name: 'search'
})

export class SearchPipe implements PipeTransform {
    transform(searchString: any, type1: any, type2: any, type3: any, data: any) {
        let filteredData = [];
        let stringMatch = new RegExp(searchString, 'i');
        for (let i = 0; i < data.length; i++) {
            let count = 0;
            let item = data[i];
            // Object.keys(item).forEach((value:any) => {
            //     if (value !== 'CreatedDate' && value !== 'LastModifiedDate' && stringMatch.test(item[value])) {
            //        count++;
            //    }
            //});
            //if (count > 0)  {
            //     filteredData.push(item);
            // }
            if (stringMatch.test(item[type1]) || stringMatch.test(item[type2]) || stringMatch.test(item[type3])) {
                filteredData.push(item);
            }
        }
        return filteredData;

    }
}
