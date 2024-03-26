# Naive Terminal Watchdog
A simple terminal output analyzer for interactive environments with in-place update.

## Why do you need this

You are dealing with terminal sessions with live updating fields (e.g., most system monitoring tools like the `top` family), and you somehow want to keep a record on the field changes, dumping them to a file. You want to keep track of changes to variable(s), located by its/their row(s) and column(s) on the terminal.

## Lengthy explaination

Terminal output redirection to file is a very common method to keep record of whatever you are running.
However, when you try to do so on programs like `top` that has a live-updating session, everything you knew before no longer works.
No matter you are simply redirect the pipeline or using tools like `script` to record an interactive session,
it is always a very challenging task to get a text-based ouput for these middle states.

This is due to the nature of terminal output, which is a *streaming* process. This means everything got sent out can not be revoked.
What if you just want to update something shown on terminal, like the dashboard in `top`, then you need to use the cursor magic.

By toggling the cursor, similar to moving the C pointer, you can re-position your writing location. For example, you can change the 
cursor location to the beginning of the word you want to update, any write would then override the old data.

Fancy isn't it! But for logging analysis, this is the worst things to have. Most tools we have their way to deal with these control 
events, which tends to hide them from users. For example, `cat` by default would show the final state of the output after all the 
re-drawing.

> Using `cat -v` enable you to see the truth.

As a result, you can only deal with raw data, handling these escape character to learn about the intermediate state change.
And that's what I am doing here in the script.

## Methodology

Let's say we are looking for any changes on variable locating at *Column **X*** and *Row **Y***

We are trying to find the string "^[[**X**;**Y**H" (e.g., *^[[5;22H*), this is the exact command for shifting the cursor location.
The value after this string is what we look for, the changes to the field, ending before the next escape character sequence (the "^[[**X**;**Y**H")

> TODO: it could also be other control sequence in the end though.

```bash
awk '{
        while (match($0, /\^\[\[5;22H  ([0-9,]*)\^\[\[/)) {
            value = substr($0, RSTART + 10, RLENGTH - 14); 
            print value; 
            $0 = substr($0, RSTART + RLENGTH)
        } 
    }' <<< "$input_string"
```

## Usage

### Capture data trace

In my case, I am using `script` to capture the terminal output.

### Offline Analyze

Before running the analyze script, remember to check the `src/config.json`
You need to define the location of the field, which include finding out the point got updated.
The length of the written data doesn't matter, at least for now, since I am using REGEX to determin the ending point.

> Most of the time, the update happens at the BEGINNING of the updating field.

```bash
cd src
./watchdog.sh ../data/pktgen-dpdk-dry-run.txt
```
*Replace the ../data/pktgen-dpdk-dry-run.txt with your trace*

## Notices

- Environment Requirements  
You might need to install the `jq`, `mawk` tools to parse json configuration files.
For example, on ubuntu you can install `jq` with `sudo apt install jq`

- Input file type  
Although there should be no difference in content given different file extension,
it seems that different extension could have their own interpretation for escape
characters, which is the basic target we are looking for in our script.
It is possible to adopt corresponding characters to these file extentions. But I 
am just a poor developer, and I need food to do so.

- Modifying *config.json* on demand  
If you want to add more capturing point, define them in *config.json*.
  - **name**: Not really used now
  - **column** & **row**: Coordinates of capturing points
  - **regex**: Expected value format in REGEX.
  - **output**: Output file name, place under the *res* directory (created on runtime)

## Reference
Thanks to the [Poor man's Profiler](https://poormansprofiler.org), although there isn't any connection between these two, I am greatly motivated by the profiler thus want to make this little tool then. His example tells me that even a simple bash script can still be very useful.