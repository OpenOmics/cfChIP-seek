#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# Python standard library
from __future__ import print_function
from ast import Index
import os, sys

# Local imports
from utils import (
    Colors,
    err,
    fatal
)


def peakcalls(file, delim='\t'):
    """Reads and parses a sample sheet, peakcall.tsv, into a dictionary. 
    This file acts as a sample sheet to gather sample metadata and define 
    relationship betweeen groups of samples. This file is used to pair a
    ChIP sample with its input sample. This tab delimited file contains
    three columns. One column for the basename of the ChIP sample, one
    column for the basename of the paired sample, and lastly, one column
    for the name of the sample's group. It is worth noting that a sample
    can belong to more than one group. A 1:M sample to group relationship
    can be denoted by seperating muliptle groups with commas (i.e. ',').
    This group information is used downstream in the pipeline for DBA. 
    Comparisons between groups can be made with a constrast.tsv file.
    This function returns a tuple containing the ChIP-input dictionary
    and a second dictionary containing group to sample lists.
    @Example: peakcall.tsv
        ChIP    Input   Group
        cfChIP_001	Input_001	G1,G4
        cfChIP_002	Input_002	G1,G4
        cfChIP_003	Input_003	G1,G4
        cfChIP_004	Input_004	G2,G5
        cfChIP_005	Input_005	G2,G5
        cfChIP_006	Input_006	G2,G5
        cfChIP_007	Input_007	G3,G5
        cfChIP_008	Input_008	G3,G5
        cfChIP_009	Input_009	G3
        cfChIP_000	Input_000	G3
    
    >> chip2input, groups = peakcalls('peakcall.tsv')
    >> chip2input
    {
        'cfChIP_002': 'Input_002',
        'cfChIP_003': 'Input_003',
        'cfChIP_000': 'Input_000',
        'cfChIP_001': 'Input_001',
        'cfChIP_006': 'Input_006',
        'cfChIP_007': 'Input_007',
        'cfChIP_004': 'Input_004',
        'cfChIP_005': 'Input_005',
        'cfChIP_008': 'Input_008',
        'cfChIP_009': 'Input_009'
    }
    >> groups
    {
        'G1': ['cfChIP_001', 'cfChIP_002', 'cfChIP_003'],
        'G2': ['cfChIP_004', 'cfChIP_005', 'cfChIP_006'],
        'G3': ['cfChIP_007', 'cfChIP_008', 'cfChIP_009', 'cfChIP_000'],
        'G4': ['cfChIP_001', 'cfChIP_002', 'cfChIP_003'],
        'G5': ['cfChIP_004', 'cfChIP_005', 'cfChIP_006', 'cfChIP_007', 'cfChIP_008'],
    }
    @param file <str>:
        Path to peakcall TSV file.
    @return pairs <dict[str]>:
        Dictionary containing ChIP-input pairs, where each key is ChIP 
        sample and its value is its matched input sample
    @return groups <dict[str]>:
        Dictionary containing group to samples, where each key is group 
        and its value is a list of samples belonging to that group
    """

    fh = open(file, 'r')
    c = Colors()

    try:
        header = [col.lower() for col in next(fh).strip().split(delim)]
    except StopIteration:
        err('{}{}Error: peakcall file, {}, is empty!{}'.format(c.bg_red, c.white, file, c.end))
        fatal('{}{}Please add ChIP-Input pairs and group information to the file and try again.{}'.format(c.bg_red, c.white, c.end))
    
    try:
        # Get index of ChIP, input, Group
        # columns for parsing the file
        c_index = header.index('chip')
        i_index = header.index('input')
        g_index = header.index('group')
    except ValueError:
        # Missing column names or header in peakcall file
        # This can also occur if the file is not actually 
        # a tab delimited file.
        # TODO: Add a check to see if the file is actually
        # a tab delimited file, i.e. a TSV file.
        err(
            '{}{}Warning: {} is missing at least one of the following column names: ChIP, Input, Group {}'.format(
                c.bg_yellow,
                c.black,
                file,
                c.end
            )
        )
        err('{}{}\t  └── Making assumptions about columns in the peakcall file... 1=ChIP, 2=Input, 3=Group {}'.format(
            c.bg_yellow,
            c.black,
            c.end)
        )
        # Setting column indexes to the following defaults
        c_index = 0 # ChIP sample column
        i_index = 1 # Input sample column
        g_index = 2 # Group information column

    # Parse the ChIP, input pairs and 
    # grab group information 
    pairs = {}
    groups = {}
    for line in fh:
        linelist = [l.strip() for l in line.split(delim)]
        # Parse Input information
        try:
            input_sample = linelist[i_index]
        except IndexError:
            # No matching input sample,
            # perform CHIP-only peak calling
            input_sample = ""
        # Parse Chip information
        try:
            chip_sample = linelist[c_index]
            if not chip_sample: continue  # skipover empty string
        except IndexError:
            # No ChIP sample, skip over line
            continue
        # Parse Group Information
        try:
            group = linelist[g_index]
            if not group: continue # skip over empty string
        except IndexError:
            continue
        # Check for multiple groups
        multiple_groups = group.split(',')
        multiple_groups = [g.strip() for g in multiple_groups]
        for g in multiple_groups:
            if g not in groups:
                groups[g] = []
            if chip_sample not in groups[g]:
                groups[g].append(chip_sample)
    
        # Add ChIP, input pairs to dictionary
        pairs[chip_sample] = input_sample

    # Close open file handle
    fh.close()

    return pairs, groups


def contrasts(file, groups, delim='\t'):
    """Reads and parses the group comparison file, contrasts.tsv, into a 
    dictionary. This file acts as a config file to setup contrasts between
    two groups, where groups of samples are defined in the peakcalls.tsv file.
    This information is used in differential analysis, like differential binding
    analysis or differential gene expression, etc. 
    @Example: contrasts.tsv
        G2  G1
        G4  G3
        G5  G1
    >> contrasts = contrasts('contrasts.tsv', groups = ['G1', 'G2', 'G3', 'G4', 'G5'])
    >> contrasts
    [
        ["G2",  "G1"],
        ["G4",  "G3"],
        ["G5",  "G1"]
    ]
    @param file <str>:
        Path to contrasts TSV file.
    @param groups list[<str>]:
        List of groups defined in the peakcall file, enforces groups exist.
    @return comparisons <list[list[str, str]]>:
        Nested list contain comparsions of interest.  
    """

    c = Colors()
    errors = []
    comparsions = []
    line_number = 0
    with open(file) as fh:
        for line in fh:
            line_number += 1
            linelist = [l.strip() for l in line.split(delim)]
            try:
                g1 = linelist[0]
                g2 = linelist[1]
                if not g1 or not g2: continue # skip over empty lines
            except IndexError:
                # Missing a group, need two groups to tango
                # This can happen if the file is NOT a TSV file,
                # and it is seperated by white spaces, :(  
                err(
                '{}{}Warning: {} is missing at least one group on line {}: {}{}'.format(
                    c.bg_yellow,
                    c.black,
                    file,
                    line_number,
                    line.strip(),
                    c.end
                    )
                )
                err('{}{}\t  └── Skipping over line, check if line is tab seperated... {}'.format(
                    c.bg_yellow,
                    c.black,
                    c.end)
                )
                continue
            # Check to see if groups where defined already,
            # avoids user errors and spelling errors
            for g in [g1, g2]:
                if g not in groups:
                    # Collect all error and report them at end
                    errors.append(g)
            
            # Add comparsion to list of comparisons
            if [g1, g2] not in comparsions:
                comparsions.append([g1, g2])

    if errors:    
        # One of the groups is not defined in peakcalls
        err('{}{}Error: the following group(s) in "{}" are not defined in peakcall file! {}'.format(
            c.bg_red, 
            c.white,
            file,
            c.end)
        )
        fatal('{}{}\t  └── {} {}'.format(
            c.bg_red,
            c.white,
            ','.join(errors),
            c.end)
        )
    
    return comparsions


if __name__ == '__main__':
    # Testing peakcall TSV parser
    print('Parsing peakcall file...')
    chip2input, groups = peakcalls(sys.argv[1])
    print(chip2input)
    print(groups)
    print('Parsing contrasts file...')
    comparsions = contrasts(sys.argv[2], groups=groups.keys())
    print(comparsions)
