preprocess_idf <- function(idf) {
    # make sure weather file input is respected
    idf$SimulationControl$Run_Simulation_for_Weather_File_Run_Periods <- "Yes"

    # make sure energy consumption is presented in kWh
    idf$OutputControl_Table_Style$Unit_Conversion <- "JtoKWH"

    # add meter outputs to get hourly time-series energy consumption
    meters <- c(
        "Cooling:Electricity",
        "Heating:Electricity",
        "InteriorLights:Electricity",
        "ExteriorLights:Electricity",
        "InteriorEquipment:Electricity",
        "Fans:Electricity",
        "Pumps:Electricity"
    )
    idf$add(Output_Meter := list(meters, "Hourly"))

    # make sure the modified model is returned
    idf
}

read_end_use <- function(job) {
    end_use <- job$tabular_data(table_name = "End Uses", wide = TRUE)[[1]] %>%
        select(case, category = row_name, electricity = `Electricity [kWh]`)

    bldg_area <- job$tabular_data(table_name = "Building Area", wide = TRUE)[[1]] %>%
        select(case, category = row_name, area = `Area [m2]`) %>%
        filter(category == "Total Building Area") %>%
        select(case, area)

    end_use %>%
        left_join(bldg_area, "case") %>%
        mutate(electricity_per_area = electricity / area) %>%
        select(-area)
}

plot_end_use <- function(end_use) {
    end_use %>%
        filter(category != "Total End Uses") %>%
        mutate(proportion = electricity_per_area / sum(electricity_per_area)) %>%
        filter(proportion > 0.01) %>%
        mutate(ypos = cumsum(proportion)- 0.5 * proportion) %>%
        mutate(category = forcats::fct_relevel(category, "Heating", after = Inf)) %>%
        ggplot(aes("", proportion, fill = category)) +
        geom_bar(stat = "identity", width = 1, color = NA, size = 0.2) +
        geom_text(aes(x = 1.2,
                      label = sprintf("%s:\n%s", category, scales::percent(proportion, 0.1))),
                  position = position_stack(vjust = 0.5), size = 4, color = "grey30",
                  fontface = "bold") +
        coord_polar("y", start = 0) +
        theme_void() +
        paletteer::scale_fill_paletteer_d("rcartocolor::Temps")
}