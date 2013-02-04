/*
 * Copyright (C) 2012 Emmanuel Durand
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 */

#include <iostream>
#include <fstream>
#include <string>

#include "glib.h"
#include "glib/gstdio.h"
#include "opencv2/opencv.hpp"

using namespace std;

static gchar* gCsvFile = NULL;
static gboolean gExtractNbrBubble = FALSE;
static gboolean gVerbose = FALSE;
static GOptionEntry gEntries[] =
{
    {"verbose", 'v', 0, G_OPTION_ARG_NONE, &gVerbose, "Verbose output", NULL},
    {"csv", 'c', 0, G_OPTION_ARG_STRING, &gCsvFile, "Input file which defines a bubble", NULL},
    {"bbl", 'b', 0, G_OPTION_ARG_NONE, &gExtractNbrBubble, "Create directory name from number in CSV file", NULL},
    {NULL}
};

/****************/
int parseArgs(int argc, char** argv)
{
    GError* error = NULL;
    GOptionContext* context;

    context = g_option_context_new("- makeFakeBubbles, tool dedicated to the Turcot project");
    g_option_context_add_main_entries(context, gEntries, NULL);

    if (!g_option_context_parse(context, &argc, &argv, &error))
    {
        cout << "Error while parsing options: " << error->message << endl;
    }

    if (gCsvFile == NULL)
    {
        cout << "You need to specify a CSV source file" << endl;
        return 1;
    }

    return 0;
}

/****************/
cv::Mat createRandomImg()
{
    int r, g, b;
    r = rand() % 255;
    g = rand() % 255;
    b = rand() % 255;

    cv::Mat img = cv::Mat::zeros(16, 24, CV_8UC3);
    for (int x = 0; x < 24; ++x)
        for (int y = 0; y < 16; ++y)
        {
            img.at<cv::Vec3b>(y, x)[0] = b;
            img.at<cv::Vec3b>(y, x)[1] = g;
            img.at<cv::Vec3b>(y, x)[2] = r;
        }

    return img;
}

/****************/
int main(int argc, char** argv)
{
    // Loading args
    int result = parseArgs(argc, argv);
    if (result != 0)
        return result;
    
    // Loading the csv
    ifstream file;
    file.open(gCsvFile, ifstream::in);
    if (!file.good())
    {
        cout << "Error while reading file " << gCsvFile << endl;
        return 1;
    }

    // Get the filename without ext
    string fileStr = gCsvFile;
    string point = ".";
    size_t pos = fileStr.find(point);
    string fileNoExt = fileStr.substr(0, pos);
    cout << fileNoExt << endl;

    string buffer;
    // Read the first line
    getline(file, buffer);

    // Loop
    string currentBubble = "none";

    // If we use only the filename to create the subdir
    if (!gExtractNbrBubble)
    {
        g_mkdir(fileNoExt.c_str(), 0755);
        g_chdir(fileNoExt.c_str());
    }

    while (!file.eof())
    {
        string bubble, id;
        // Extract the values needed
        for (int i=0; i < 6; ++i)
            getline(file, buffer, ';');

        id = buffer;

        if (id == string(""))
            continue;

        for (int i=0; i < 6; ++i)
            getline(file, buffer, ';');

        bubble = buffer;

        getline(file, buffer);

        // Check if we are in a new bubble
        if (bubble != currentBubble && gExtractNbrBubble)
        {
            g_mkdir(bubble.c_str(), 0755);
            
            if (currentBubble != string("none"))
                g_chdir("..");
            g_chdir(bubble.c_str());

            currentBubble = bubble;
        }

        string filename = string("DSC_") + id + string(".png");

        if (gVerbose)
            cout << filename << endl;

        cv::imwrite(filename.c_str(), createRandomImg());
    }
}
