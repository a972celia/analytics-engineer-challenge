# Analytics Engineer home exercise

Hi, imagine a situation when you woke up as an Analytics Engineer at an amazing company named *"Ovecell"* that is providing an app to learn how to play musical instruments. 
When you arrived at your workspace and opened your company messager app you noticed two direct messages. 
One of them is from a fellow marketing analyst who is planning to make a cross-network analysis, can you help them? 
The second message is from an intern who recently started at "Ovecell", looks like they need a code review.

--------------------------------------------
_Well, let's go straight to the messages:_


## Messager:

> --..--
>
> --/ **Marketing Analyst** *This morning 8am:*
> Hey there! We have a new challenge from the marketing team for you!
>
>--/ **Marketing Analyst** *This morning 8am:* As you know, we pull in loads of marketing data through third-party tools, and the main type of data we get is reports from various ad networks (such as Google Ads, Facebook Ads, TikTok Ads, etc.) regarding their performance. **Our main ad networks now are Ad Network 1 and Ad Network 2**, and in the reports below you can find our marketing spend, amount of ad impressions we got and the number of clicks on our ads by day.
>
>--/ **Marketing Analyst** *This morning 8am:* Since each ad network offers a unique set of dimensions, analyzing the data becomes a bit challenging as it may differ from one ad network to another. We understand that unifying these reports to a single datamart would make things much easier for everyone. Could you please create such a datamart for us?
>
>--/ **Marketing Analyst** *This morning 8am:* **The most important dimension for the marketing team is geo**, so please do your best to get the location on the most detailed level available. One thing to note about our third-party tool is that it only includes data in each source table where all the dimensions are available. So, if a piece of data is missing a dimension, it will not be included in the report. And in general it is good to double check data from thrid party. 
>
>--/ **Marketing Analyst** *This morning 8am:* Here you can find all attached source files with data for your model: 
>```
ae_ad_network_1_campaign_updates.csv, ae_ad_network_1_geo_dictionary.csv, 
ae_ad_network_1_country_report.csv, ae_ad_network_1_detailed_report.csv, 
ae_ad_network_2_report.csv
>```
>pay attention to the file `data_schema.md` (`data_schema.pdf`) where you can find schema and fileds description 
>
>--/ **Marketing Analyst** *This morning 8am:* Thanks for your help!

...

> --..--
>
> --/ **Intern** *Later morning 10am:* Hi, I'm a new intern in our product analytics team! My teammates suggested to me that you are good at reviewing SQL model code. Can you make one review for me? 
>
> --/ **Intern** *Later morning 10am:* attached file: `dim_activity.sql`
>
> --/ **Intern** *Later morning 10am:* I'm trying to build a dimension model that has the most commonly requested user activity data: the first song played, the last song played and the number of challenges that the user had. Also, a most common request is the fact that the user played a song in challenges collection. And since we have no flag in a song played event that indicates opening from challenges: I decided to find the closest challenge opened event before a song play.
>
> --/ **Intern** *Later morning 10am:* Another problem with this table is that it takes a lot of time to build. Maybe I'm doing something very wrong?
>
> --/ **Intern** *Later morning 10am:* However, I will anyway build some more aggregated tables on top of this one. Maybe I can make  those incremental, you know, in DBT we can make tables that only add new data, so all dependent models will be incremental, that are build on top of current one.
>
> --/ **Intern** *Later morning 10am:* But anyway, can I have a review from you? Please!


## Requirements:
For the first part (marketing) of the task, we expect a data model based on SQL file(s) or templated SQL. We recommend creating a DBT project [^1] because this is our primary tool. However, if you are not familiar with it just SQL files with 
create table / select statements is good enough. 
As a separate SQL file, you can provide queries to test the model, if you want to write tests as well. We do appreciate data tests. Or you can use DBT for data testing and it is really good for that. 
*Remember, at the end we expect one table that combines two ad networks.*

For the second part (review) we expect some response as an actual review. You, of course, can just write optimised SQL but it would be nicer to have it in a review form, It is not necessary to write a working SQL as a result. Approach it as you would really give an advice to an intern. 

[^1]: [DBT](https://www.getdbt.com/product/what-is-dbt/) Data Build Tool. This is what we use for data modelling at Yousician. You can find more information below. 

## Environment

You can setup any environment as you like, but if you do not have any
preferences, we can suggest a small guide below:


1. [**DuckDB**](https://duckdb.org/) is an in-process SQL OLAP database management
system; its syntax is rich enough, but the installation is significantly more
convenient compared to heavier alternatives;


2. [**DBT**](https://www.getdbt.com/product/what-is-dbt/) is a SQL-first
transformation workflow, which helps to organize data models, dependencies and
testing; it supports multiple databases and warehouses, but for the sake of
simplicity, we suggest using it together with **DuckDB**; an example can be
found [**here**](https://github.com/dbt-labs/jaffle_shop_duckdb);


3. [**DBeaver**](https://dbeaver.io/) or [**VSCode DuckDB
extension**](https://github.com/RandomFractals/duckdb-sql-tools) as a UI
client for viewing the data and writing queries; the VSCode extension supports
only `duckdb~=0.6.1` at the time of writing, make sure to install the correct
version.

