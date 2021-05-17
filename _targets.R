library(targets)
library(tarchetypes)

# load packages
library(tidyverse)
library(eplusr)
library(fs)

# load functions
source("R/functions.R")

list(
    # file dependencies
    tar_target(path_idf, format = "file", "data-raw/RefBldgMediumOfficeNew2004_Chicago.idf"),
    tar_target(path_epw, format = "file", "data-raw/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"),

    # single simulation
    tar_target(job, {
        idf <- read_idf(path_idf) %>% preprocess_idf()

        # save the modified model into a temporary folder
        idf$save(path("data/sim", path_file(idf$path())), overwrite = TRUE)
        idf$run(path_epw)
    }),
    tar_target(tbl_end_use, job %>% read_end_use()),
    tar_target(p_end_use, tbl_end_use %>% plot_end_use()),

    # build paper
    tar_render(paper, "analysis/paper/paper.Rmd", output_format = "all")
)
