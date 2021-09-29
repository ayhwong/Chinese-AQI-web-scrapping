library(rvest)
library(tidyverse)
library(RSelenium)

## Set up selenium::
rd = rsDriver(port = as.integer(1234))
remDr = rd$client
#remDr$open()

## Get links to each city 
main_url = 'https://www.aqistudy.cn/historydata/'

link_cities = main_url %>% read_html() %>% html_nodes('a') %>% 
  html_attr('href') %>% .[21:434]

# Scrape all cities

count = 14
t = Sys.time()
for (link_city in link_cities){
  
  # Stepping
  
  count = count +1 
  print(Sys.time() - t)
  print(city_name)
  
  ## Get links for each month
  
  link_city = paste0(main_url,link_city)
  city_name = substr(link_city,str_locate(link_city,'=')[1]+1,str_length(link_city))
  links_month = link_city %>% read_html() %>% 
    html_nodes('a') %>% html_attr('href') %>% .[grep(.,pattern = '&month=')] %>%
    paste0(main_url,.)

  ## Scrape daily data
  for (link in links_month){
    remDr$navigate(link)
    Sys.sleep(1.5)
    tbl = read_html(remDr$getPageSource()[[1]]) %>%
      html_nodes('table') %>%
      html_table() %>% .[[1]] %>% .[,-3] 
    colnames(tbl)[1] = 'Date'
    
    date_identifier = substr(link,str_length(link) - 5,str_length(link))
    
    ## Only output table when it is not empty
    
    if (nrow(tbl) > 0){
      csv_file_name = paste0('./',city_name,'_',date_identifier,'.csv')
      write_excel_csv(x = tbl, path = csv_file_name)
    }
  }
  
  ## Restart Chrome every 15 cities to free memory and speed up program
  if (count == 15){
    count = count - 15
    remDr$close()
    remDr$open()
    gc()
  }
}

# Close Selenium Server
remDr$close()
rm(rd)
gc()