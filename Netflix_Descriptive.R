tt <- tt_load("2021-04-20")



# Selecting the films in the data set, creating a numeric variable for film
## duration called "runtime", creating a numeric variable for year added
netflix_movies <- tt$netflix_titles %>%
  filter(type == "Movie") %>%
  mutate(runtime = as.numeric(str_sub(duration, end = -5))) %>%
  mutate(year_added = as.numeric(str_sub(date_added, start = -4)))

# Creating a vector of MPA film ratings
mpa_tt <- c("General Audience","Parental Guidance","Strongly Cautioned People","Strictly Restricted","Adults Only")

# Creating a list of the top categories ("listed in") on Netflix
top_listings <- tt$netflix_titles %>%
  separate_rows(listed_in, sep = ", ") %>%
  count(listed_in, sort = TRUE) %>%
  select(listed_in) %>%
  head()
# Counting the occurrences of words in the descriptions of these top categories
top_listing_words <- tt$netflix_titles %>%
  separate_rows(listed_in, sep = ", ") %>%
  filter(listed_in %in% top_listings$listed_in) %>%
  select(listed_in, description) %>%
  unnest_tokens(word, description) %>%
  anti_join(stop_words, by = "word") %>%
  count(listed_in, word, sort = TRUE)
# Counting the total number of words in the descriptions of these top categories
total_words <- top_listing_words %>%
  group_by(listed_in) %>%
  summarise(total = sum(n))
# Adding word totals to individual word counts
top_listing_words <- left_join(top_listing_words, total_words, by = "listed_in")
# Adding tf-idf to these word counts
top_listing_words <- top_listing_words %>%
  bind_tf_idf(word, listed_in, n)






# Plotting distributions of film length according to MPA rating
netflix_movies %>%
  filter(type == "Movie" & !is.na(rating)) %>%
  filter(rating %in% MPA_ratings) %>%
  mutate(rating = factor(rating, levels = rev(MPA_ratings))) %>%
  ggplot(aes(x = rating, y = runtime, fill = rating)) +
  geom_violin() +
  geom_hline(yintercept = 90, linetype = 2) +
  coord_flip() +
  theme_classic() +
  scale_fill_viridis_d() +
  theme(legend.position = "none") +
  labs(x = "Film Rating", y = "Film Duration (in minutes)",
       title = "Film Rating vs Duration in Minutes",
       subtitle = "Films focused at younger audiences tends to be lesser than others")




#Alternate View - YOY vs Animated Film Details :

netflix_movies %>%
  filter(rating %in% MPA_ratings & !is.na(year_added)) %>%
  select(year_added, rating) %>%
  group_by(year_added) %>%
  count(rating) %>%
  mutate(percentage = n / sum(n)) %>%
  mutate(rating = factor(rating, levels = rev(MPA_ratings))) %>%
  ggplot(aes(x = year_added, y = percentage, fill = rating)) +
  geom_col() +
  theme_classic() +
  scale_fill_viridis_d() +
  scale_x_continuous(breaks = seq(2008, 2021, by = 1)) +
  scale_y_continuous(labels = scales::percent_format(scale = 100)) +
  labs(y = "Percentage Films got added in Netflix", x = "Year Details", fill = "Animated Film Ratings",
       title = "Animated rated films added to Netflix on yearly basis",
       subtitle = "Year vs Percentage of Motion Picture Association (MPA) rated films added")




top_listing_words %>%
  slice_max(tf_idf, n = 20) %>%
  ggplot(aes(tf_idf, fct_reorder(word, tf_idf), fill = listed_in)) +
  geom_col() +
  theme_classic() +
  labs(y = "Word", x = "Term frequency-inverse document frequency (tf-idf)",
       fill = "Netflix categories",
       title = "Significant words in common Netflix category descriptions",
       subtitle = "Words that appear often in these categories and not others")