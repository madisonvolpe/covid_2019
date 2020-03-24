cc <- transformed_data$Confirmed
values <- paste0(apply(cc, 1, function(x) paste0("('", paste0(x, collapse = "', '"), "')")), collapse = ", ")
part_one <- paste0("INSERT INTO confirmed_cases VALUES ", values)
part_two <- 'ON CONFLICT ("Province_State", "Country_Region", "Date") DO NOTHING;'

query <- paste0(part_one, part_two)
