# Hacking Algorithms into H<sub>2</sub>O: Grep

> This is a presentation of hacking a simple algorithm into the new dev-friendly
branch of H2O, [h2o-dev](https://github.com/0xdata/h2o-dev/).

> This is one of three "Hacking Algorithms into H2O" tutorials. All tutorials
start out the same: getting the h2o-dev code and building it.  They are the
same until the section titled [Building Our Algorithm: Copying from the
Example](#customizedStartsHere), and then the content is customized for each
algorithm.  This tutorial describes computing [Grep](http://en.wikipedia.org/wiki/Grep).


## What is H<sub>2</sub>O-dev ?

As I mentioned, H2O-dev is a dev-friendly version of H2O, and is soon to be our
only version.  What does "dev-friendly" mean?  It means:

- **No classloader:** The classloader made H2O very hard to embed in
  other projects.  No more!
  [Witness H2O's embedding in Spark](http://0xdata.com/blog/2014/09/Sparkling-Water/).
- **Fully integrated into IdeaJ:** You can right-click debug-as-junit any of
  the junit tests and they will Do The Right Thing in your IDE.
- **Fully gradle-ized and maven-ized:** Running `gradlew build` will download
  all dependencies, build the project, and run the tests.

These are all external points.  However, the code has undergone a major
revision *internally* as well.  What worked well was left alone, but what
was... gruesome... has been rewritten.  In particular, it's now much easier to
write the "glue" wrappers around algorithms and get the full GUI, R, REST &
JSON support on your new algorithm.  You still have to write the math, of
course, but there's not nearly so much pain on the top-level integration.

At some point, we'll flip the usual [H2O](https://github.com/0xdata/h2o/)
github repo to have h2o-dev as our main repo, but at the moment, h2o-dev does
not contain all the functionality in H2O, so it is in its own repo.

------------------------------


## Building H<sub>2</sub>O-dev

I assume you are familiar with basic Java development and how github
repo's work - so we'll start with a clean github repo of h2o-dev:

        C:\Users\cliffc\Desktop> mkdir my-h2o
        C:\Users\cliffc\Desktop> cd my-h2o
        C:\Users\cliffc\Desktop\my-h2o> git clone https://github.com/0xdata/h2o-dev

This will download the h2o-dev source base; took about 30secs for me from home
onto my old-school Windows 7 box.  Then do an initial build:

        C:\Users\cliffc\Desktop\my-h2o> cd h2o-dev
        C:\Users\cliffc\Desktop\my-h2o\h2o-dev> .\gradlew build
    
        ...
        :h2o-web:test UP-TO-DATE
        :h2o-web:check UP-TO-DATE
        :h2o-web:build
    
        BUILD SUCCESSFUL
    
        Total time: 11 mins 41.138 secs
        C:\Users\cliffc\Desktop\my-h2o\h2o-dev>
     
The first build took about 12mins, including all the test runs.  Incremental
gradle-based builds are somewhat faster:

        C:\Users\cliffc\Desktop\my-h2o\h2o-dev> gradle --daemon build -x test
    
        ...
        :h2o-web:signArchives SKIPPED
        :h2o-web:assemble
        :h2o-web:check
        :h2o-web:build
    
        BUILD SUCCESSFUL
    
        Total time: 1 mins 44.645 secs
        C:\Users\cliffc\Desktop\my-h2o\h2o-dev>

But faster yet will be IDE-based builds. There's also a functioning `Makefile`
setup for old-schoolers like me; it's a lot faster than gradle for incremental
builds.

------------------------------

While that build is going, let's look at what we got.  There are 4 top-level
directories of interest here:

- **`h2o-core`**: The core H2O system - including clustering, clouding,
  distributed execution, distributed Key-Value store, the web, REST and JSON
  interfaces.  We'll be looking at the code and javadocs in here - there are a
  lot of useful utilities - but not changing it.
- **`h2o-algos`**: Where most of the algorithms lie, including GLM and Deep
  Learning.  We'll be copying the `Example` algorithm and turning it into
  a grep algorithm.
- **`h2o-web`**: The web interface and JavaScript.  We will use jar files
  from here in our project, but probably not need to look at the code.
- **`h2o-app`**: A tiny sample Application which drives h2o-core and h2o-algos,
  including the one we hack in.  We'll add one line here to teach H2O about our
  new algorithm.
  
Within each top-level directory, there is a fairly straightforward maven'ized
directory structure:

        src/main/java - Java source code
        src/test/java - Java  test  code

In the Java directories, we further use `water` directories to hold core H2O
functionality and `hex` directories to hold algorithms and math:

        src/main/java/water - Java core source code
        src/main/java/hex   - Java math source code

Ok, let's setup our IDE.  For me, since I'm using the default IntelliJ IDEA setup:

        C:\Users\cliffc\Desktop\my-h2o\h2o-dev> gradlew idea
    
        ...
        :h2o-test-integ:idea
        :h2o-web:ideaModule
        :h2o-web:idea
    
        BUILD SUCCESSFUL
    
        Total time: 38.378 secs
        C:\Users\cliffc\Desktop\my-h2o\h2o-dev>

------------------------------


### Running H<sub>2</sub>O-dev Tests in an IDE 

Then I switched to IDEAJ from my command window.  I launched IDEAJ, selected
"Open Project", navigated to the `h2o-dev/` directory and clicked Open.  After IDEAJ opened, I clicked the Make project button (or Build/Make Project or ctrl-F9) and
after a few seconds, IDEAJ reports the project is built (with a few dozen
warnings).

Let's use IDEAJ to run the JUnit test for the `Example` algorithm I mentioned
above.  Navigate to the `ExampleTest.java` file. I used a quick double-press of
Shift to bring the generic project search, then typed some of
`ExampleTest.java` and selected it from the picker.  Inside the one obvious
`testIris()` function, right-click and select `Debug testIris()`.  The testIris code
should run, pass pretty quickly, and generate some output:

```
    "C:\Program Files\Java\jdk1.7.0_67\bin\java" -agentlib:jdwp=transport=dt_socket....
    Connected to the target VM, address: '127.0.0.1:51321', transport: 'socket'
```

<pre style="background:yellow">
    11-08 13:17:07.536 192.168.1.2:54321     4576   main      INFO: ----- H2O started  -----
    11-08 13:17:07.642 192.168.1.2:54321     4576   main      INFO: Build git branch: master
    11-08 13:17:07.642 192.168.1.2:54321     4576   main      INFO: Build git hash: cdfb4a0f400edc46e00c2b53332c312a96566cf0
    11-08 13:17:07.643 192.168.1.2:54321     4576   main      INFO: Build git describe: RELEASE-0.1.10-7-gcdfb4a0
    11-08 13:17:07.643 192.168.1.2:54321     4576   main      INFO: Build project version: 0.1.11-SNAPSHOT
    11-08 13:17:07.644 192.168.1.2:54321     4576   main      INFO: Built by: 'cliffc'
    11-08 13:17:07.644 192.168.1.2:54321     4576   main      INFO: Built on: '2014-11-08 13:06:53'
    11-08 13:17:07.644 192.168.1.2:54321     4576   main      INFO: Java availableProcessors: 4
    11-08 13:17:07.645 192.168.1.2:54321     4576   main      INFO: Java heap totalMemory: 183.5 MB
    11-08 13:17:07.645 192.168.1.2:54321     4576   main      INFO: Java heap maxMemory: 2.66 GB
    11-08 13:17:07.646 192.168.1.2:54321     4576   main      INFO: Java version: Java 1.7.0_67 (from Oracle Corporation)
    11-08 13:17:07.646 192.168.1.2:54321     4576   main      INFO: OS   version: Windows 7 6.1 (amd64)
    11-08 13:17:07.646 192.168.1.2:54321     4576   main      INFO: Possible IP Address: lo (Software Loopback Interface 1), 127.0.0.1
    11-08 13:17:07.647 192.168.1.2:54321     4576   main      INFO: Possible IP Address: lo (Software Loopback Interface 1), 0:0:0:0:0:0:0:1
    11-08 13:17:07.647 192.168.1.2:54321     4576   main      INFO: Possible IP Address: eth3 (Realtek PCIe GBE Family Controller), 192.168.1.2
    11-08 13:17:07.648 192.168.1.2:54321     4576   main      INFO: Possible IP Address: eth3 (Realtek PCIe GBE Family Controller), fe80:0:0:0:4d5c:8410:671f:dec5%11
    11-08 13:17:07.648 192.168.1.2:54321     4576   main      INFO: Internal communication uses port: 54322
    11-08 13:17:07.648 192.168.1.2:54321     4576   main      INFO: Listening for HTTP and REST traffic on  http://192.168.1.2:54321/
    11-08 13:17:07.649 192.168.1.2:54321     4576   main      INFO: H2O cloud name: 'cliffc' on /192.168.1.2:54321, discovery address /227.18.246.131:58130
    11-08 13:17:07.650 192.168.1.2:54321     4576   main      INFO: If you have trouble connecting, try SSH tunneling from your local machine (e.g., via port 55555):
    11-08 13:17:07.650 192.168.1.2:54321     4576   main      INFO:   1. Open a terminal and run 'ssh -L 55555:localhost:54321 cliffc@192.168.1.2'
    11-08 13:17:07.650 192.168.1.2:54321     4576   main      INFO:   2. Point your browser to http://localhost:55555
    11-08 13:17:07.652 192.168.1.2:54321     4576   main      INFO: Log dir: '\tmp\h2o-cliffc\h2ologs'
    11-08 13:17:07.719 192.168.1.2:54321     4576   main      INFO: Cloud of size 1 formed [/192.168.1.2:54321]
</pre>

<pre style="background:lightblue">
    11-08 13:17:07.722 192.168.1.2:54321     4576   main      INFO: ###########################################################
    11-08 13:17:07.723 192.168.1.2:54321     4576   main      INFO:   * Test class name:  hex.example.ExampleTest
    11-08 13:17:07.723 192.168.1.2:54321     4576   main      INFO:   * Test method name: testIris
    11-08 13:17:07.724 192.168.1.2:54321     4576   main      INFO: ###########################################################
    Start Parse
    11-08 13:17:08.198 192.168.1.2:54321     4576   FJ-0-7    INFO: Parse result for _85a160bc2419316580eeaab88602418e (150 rows):
    11-08 13:17:08.204 192.168.1.2:54321     4576   FJ-0-7    INFO:        Col        type          min          max         NAs constant numLevels
    11-08 13:17:08.205 192.168.1.2:54321     4576   FJ-0-7    INFO:  sepal_len:     numeric      4.30000      7.90000                            
    11-08 13:17:08.206 192.168.1.2:54321     4576   FJ-0-7    INFO:  sepal_wid:     numeric      2.00000      4.40000                            
    11-08 13:17:08.207 192.168.1.2:54321     4576   FJ-0-7    INFO:  petal_len:     numeric      1.00000      6.90000                            
    11-08 13:17:08.208 192.168.1.2:54321     4576   FJ-0-7    INFO:  petal_wid:     numeric     0.100000      2.50000                            
    11-08 13:17:08.209 192.168.1.2:54321     4576   FJ-0-7    INFO:      class: categorical      0.00000      2.00000                           3
    11-08 13:17:08.212 192.168.1.2:54321     4576   FJ-0-7    INFO: Internal FluidVec compression/distribution summary:
    11-08 13:17:08.212 192.168.1.2:54321     4576   FJ-0-7    INFO: Chunk type    count     fraction       size     rel. size
    11-08 13:17:08.212 192.168.1.2:54321     4576   FJ-0-7    INFO:       C1          1     20.000 %     218  B     19.156 %
    11-08 13:17:08.212 192.168.1.2:54321     4576   FJ-0-7    INFO:      C1S          4     80.000 %     920  B     80.844 %
    11-08 13:17:08.212 192.168.1.2:54321     4576   FJ-0-7    INFO:  Total memory usage :     1.1 KB
    Done Parse: 488
</pre>

<pre style="background:green">
    11-08 13:17:08.304 192.168.1.2:54321     4576   FJ-0-7    INFO: Example: iter: 0
    11-08 13:17:08.304 192.168.1.2:54321     4576   FJ-0-7    INFO: Example: iter: 1
    11-08 13:17:08.305 192.168.1.2:54321     4576   FJ-0-7    INFO: Example: iter: 2
    11-08 13:17:08.306 192.168.1.2:54321     4576   FJ-0-7    INFO: Example: iter: 3
    11-08 13:17:08.307 192.168.1.2:54321     4576   FJ-0-7    INFO: Example: iter: 4
    11-08 13:17:08.308 192.168.1.2:54321     4576   FJ-0-7    INFO: Example: iter: 5
    11-08 13:17:08.309 192.168.1.2:54321     4576   FJ-0-7    INFO: Example: iter: 6
    11-08 13:17:08.309 192.168.1.2:54321     4576   FJ-0-7    INFO: Example: iter: 7
    11-08 13:17:08.310 192.168.1.2:54321     4576   FJ-0-7    INFO: Example: iter: 8
    11-08 13:17:08.311 192.168.1.2:54321     4576   FJ-0-7    INFO: Example: iter: 9
    11-08 13:17:08.315 192.168.1.2:54321     4576   main      INFO: #### TEST hex.example.ExampleTest#testIris EXECUTION TIME: 00:00:00.586 (Wall: 08-Nov 13:17:08.313) 
</pre>

```
    Disconnected from the target VM, address: '127.0.0.1:51321', transport: 'socket'
    Process finished with exit code 0
```

------------------------------

Ok, that's a pretty big pile of output - but buried it in is some cool stuff
we'll need to be able to pick out later, so let's break it down a little.

The <code style="background:yellow">yellow</code> stuff is H2O booting up a
cluster of 1 JVM.  H2O dumps out a bunch of stuff to diagnose initial cluster
setup problems, including the git build version info, memory assigned to the
JVM, and the network ports found and selected for cluster communication.  This
section ends with the line:

    11-08 13:17:07.719 192.168.1.2:54321     4576   main      INFO: Cloud of size 1 formed [/192.168.1.2:54321]

This tells us we formed a Cloud of size 1: one JVM will be running our program,
and its IP address is given.

The <code style="background:lightblue">lightblue</code> stuff is our
ExampleTest JUnit test starting up and loading some test data (the venerable
`iris` dataset with headers, stored in the H2O-dev repo's
`smalldata/iris/` directory).  The printout includes some basic stats about the
loaded data (column header names, min/max values, compression ratios).
Included in this output are the lines `Start Parse` and `Done Parse`.  These
come directly from the `System.out.println("Start Parse")` lines we can see in
the ExampleTest.java code.

Finally, the <code style="background:green">green</code> stuff is our Example
algorithm running on the test data.  It is a very simple algorithm (finds the
max per column, and does it again and again, once per requested `_max_iters`).

------------------------------

<a name="customizedStartsHere"></a>
## Building Our Algorithm: Copying from the Example

Now let's get our own algorithm framework to start playing with in place.

We want to do a grep, so let's call the code `grep`.  I cloned the
main code and model from the `h2o-algos/src/main/java/hex/example/` directory
into `h2o-algos/src/main/java/hex/grep/`, and the test from
`h2o-algos/src/test/java/hex/example/` directory into
`h2o-algos/src/test/java/hex/grep/`.

Then I copied the three GUI/REST files in `h2o-algos/src/main/java/hex/schemas`
with Example in the name (`ExampleHandler.java`, `ExampleModelV2.java`,
`ExampleV2`) to their `Grep*` variants.

I also copied the `h2o-algos/src/main/java/hex/api/ExampleBuilderHandler.java`
file to its `Grep` variant.  Finally, I renamed the files **and** file contents
from `Example` to `Grep`.

I also dove into `h2o-app/src/main/java/water/H2OApp.java` and copied the two
`Example` lines and made **their** `Grep` variants.  Because I'm old-school,
I did this with a combination of shell hacking and Emacs; about 5 minutes all
told.

At this point, back in IDEAJ, I nagivated to `GrepTest.java`, right-clicked
debug-test `testIris` again - and was rewarded with my `Grep` clone running
a basic test.  Not a very good grep, but definitely a start.


### Whats in All Those Files?

What's in all those files?  Mainly there is a `Model` and a `ModelBuilder`, and
then some support files.

> A **model** is a mathematical representation of the world, an effort to
> approximate some interesting fact with numbers.  It is a static concrete
> unchanging thing, completely defined by the rules (algorithm) and data used
> to make it.

> A **model-builder** builds a model; it is transient and active.  It exists as
> long as we are actively trying to make a model, and is thrown away once we
> have the model in-hand.

In our case, we want the regular expression matches (as a `String[]`) of the
match pattern applied to a text file - a mathematical result - so that belongs
in the `GrepModel.java` file.  The algorithm to run grep belongs in the
`GrepModelBuilder.java` file.

We also split Schemas from Models to isolate slow-moving external APIs from
rapidly-moving *internal* APIs. As a Java dev, you can hack the guts of Grep
to your heart's content, including the inputs and outputs, as long as the
externally facing V2 schemas do not change.  If you want to report new stuff or
take new parameters, you can make a new V3 schema (which is not compatible
with V2) for the new stuff.  Old external V2 users will not be affected by
your changes - you'll still have to make the correct mappings in the V2 schema
code from your V3 algorithm.

One other important hack: grep is an *unsupervised* algorithm - no training
data (no "response") tells it what the results "should" be - it's not really a
machine-learning algorithm.  So we need to hack the word `Supervised` out of
all the various class names it appears in.  After this is done, your GrepTest
probably fails to compile, because it is trying to set the response column name
in the test, and unsupervised models do not get a response to train with.  Just
delete the line for now:

```java
    parms._response_column = "class";
```

At this point, we can run our test code again (still finding the
max-per-column) instead of running grep.


### The Grep Model

The Grep model, in the file `GrepModel.java`, should contain what we expect out
of grep: the set of matches as a `String[]`.  Note that this decision *limits
us to a set of results that can be held on a single machine*.  H2O can
represent a Big Data set of results, but only in a distributed data Frame.
It's not to hard to do, but the `String[]` is easy to work with, and good for a
few million results before it gets painful.

We also want the line numbers (harder to get), and the byte offset of the match
(easier to get), and perhaps the whole matching line.  For this example we'll
skip the line numbers for a bit, and just report byte offsets and the matched
Strings.

```java
    public String[] _matches; // Our String matches
    public long[] _offsets;   // File offsets
```

Inside the `GrepModel` class, there is a class for the model's output: `class
GrepOutput`.  We'll put our grep results there.  The various support classes
and files will make sure our model's output appears in the correct REST and
JSON responses, and gets pretty-printed in the GUI.  There is also the
left-over `_maxs` array from the old Example code; we can delete that now.

My final `GrepOutput` class looks like:

```java
    public static class GrepOutput extends Model.Output {
      public String[] _matches; // Our String matches
      public long[] _offsets;   // File offsets
      public GrepOutput( Grep b ) { super(b); }
      @Override public ModelCategory getModelCategory() { return Model.ModelCategory.Unknown; }
    }
```

Now, let's turn to the *input* for our model-building process.  These are
stored in the `class GrepModel.GrepParameters`.  We already inherit an input
dataset (returned with `train()`), and some other helpers (e.g. which columns
to ignore).  For now, we can ignore everything except the input dataset from
`train()`.

However, we want some more parameters for grep: the regular expression.  Define
it next to the left-over `_max_iters` from the old Example code (which we might
as well also nuke):

```java
        public String _regex;
```

My final `GrepParameters` class looks like:

```java
      public static class GrepParameters extends Model.Parameters {
        public String _regex;       // The regex
      }
```

A bit on field naming: I always use a leading underscore `_` before all
internal field names - it lets me know at a glance whether I'm looking at a
field name (stateful, can changed by other threads) or a function parameter
(functional, private).  The distinction becomes interesting when you are
sorting through large piles of code.  There's no other fundamental reason to
use (or not use) the underscores.  *External* APIs, on the other hand, generally do
not care for leading underscores.  Our JSON output and REST URLs will strip the
underscores from these fields.

To make the GUI functional, I need to add my new regex field to the external schema
in `h2o-algos/src/main/java/hex/schemas/GrepV2.java`:

```java
    public static final class GrepParametersV2 extends ModelParametersSchema<GrepModel.GrepParameters, GrepParametersV2> {
      static public String[] own_fields = new String[] { "regex" };
  
      // Input fields
      @API(help="regex")  public String regex;
    }
```

And I need to add my result fields to the external output schema in
`h2o-algos/src/main/java/hex/schemas/GrepModelV2.java`:

```java
    public static final class GrepModelOutputV2 extends ModelOutputSchema<GrepModel.GrepOutput, GrepModelOutputV2> {
      // Output fields
      // Assume small-data results: string matches only
      @API(help="Matching strings") public String[] matches;
      @API(help="Byte offsets of matches") public long[] offsets;
```


### The Grep Model Builder

Let's turn to the Grep model builder, which includes some boilerplate we
inherited from the old Example code, and a place to put our real algorithm.
There is a basic `Grep` constructor which calls `init`:

```java
    public Grep( ... ) { super("Grep",parms); init(false); }
```

In this case, `init(false)` means "only do cheap stuff in `init`".  Init is
defined a little ways down and does basic (cheap) argument checking.
`init(false)` is called every time the mouse clicks in the GUI and is used to
let the front-end sanity parameters function as people type.  In this case
"only do cheap stuff" really means "only do stuff you don't mind waiting on
while clicking in the browser".  No computing grep in the `init()` call!

Speaking of the `init()` call, the one we got from the old Example code limits
sanity checks the now-deleted `_max_iters`.  Let's replace that with some
basic sanity checking:

```java
    @Override public void init(boolean expensive) {
      super.init(expensive);
      if( _parms._regex == null ) {
        error("regex", "regex is missing");
      } else {
        try { Pattern.compile(_parms._regex); }
        catch( PatternSyntaxException pse ) { error("regex", pse.getMessage()); }
      }
      if( _parms._train == null ) return;
      Vec[] vecs = _parms.train().vecs();
      if( vecs.length != 1 )
        error("train","Frame must contain exactly 1 Vec (of raw text)");
      if( !(vecs[0] instanceof ByteVec) )
        error("train","Frame must contain exactly 1 Vec (of raw text)");
    }
```

In the `Grep.java` file there is a `trainModel` call that is used when you
really want to start running grep (as opposed to just checking arguments).
In our case, the old boilerplate starts a `GrepDriver` in a background
thread.  Not required, but for any long-running algorithm, it is nice to have it
run in the background.  We'll get progress reports from the GUI (and from
REST/JSON) with the option to cancel the job, or inspect partial results as the
model builds.

The `class GrepDriver` holds the algorithmic meat.  The `compute2()` call
will be called by a background Fork/Join worker thread to drive all the hard
work.  Again, there is some brief boilerplate we need to go over.

First up: we need to record Keys stored in H2O's DKV: **Distributed
Key/Value** store, so a later cleanup, `Scope.exit();`, will wipe out any temp
keys.  When working with Big Data, we have to be careful to clean up after
ourselves - or we can swamp memory with Big Temps.

```java
    Scope.enter();
```

Next, we need to prevent the input datasets from being manipulated by other
threads during the model-build process:

```java
    _parms.lock_frames(Grep.this);
```

Locking prevents situations like accidentally deleting or loading a new dataset
with the same name while grep is running.  Like the `Scope.exit()` above,
we will unlock in the `finally` block.  While it might be nice to use Java locking,
or even JDK 5.0 locks, we need a *distributed* lock, which is not provided by
JDK 5.0.  Note that H2O locks are strictly cooperative - we cannot
enforce locking at the JVM level like the JVM does.

Next, we make an instance of our model object (with no result matches yet) and
place it in the DKV, locked (e.g., to prevent another user from overwriting our
model-in-progress with an unrelated grep search).

```java
    model = new GrepModel(dest(), _parms, new GrepModel.GrepOutput(Grep.this));
    model.delete_and_lock(_key);
```

Also, near the file bottom is a leftover `class Max` from the old Example code.
Might as well nuke it now.


### The Grep Main Algorithm

Finally we get to where the Real Stuff is!

Grep can be computed in a variety of ways, but for this demo I'm going to stick
with the classic JDK `Pattern` and `Match` classes.  Note that 30secs of
grep'ing the internet (well, google'ing, pretty much the same thing) pulls out
a dozen Regex packages claiming to be 1 or 2 *orders of magnitude* faster.  I
didn't try them (tempted though), and definitely worth a deeper look in the
next iteration.


My `Grep` now has a leftover loop from the old Example code running up to some
max iteration count.  Let's nuke it and just make a pass over the single Big
Data column of raw text.

```java
      // Run the main Grep Loop
      GrepGrep gg = new GrepGrep(_parms._regex).doAll(train().vecs()[0]);
```

I removed the "compute Max" code from the old Example code in the loop body.
Next up, I see code to record any new **model** (e.g. grep), and save the
results back into the DKV, bump the progress bar, and log a little bit of
progress.  For this very simple 'model' we don't need any extra iteration, and
we'll do progress on a per-byte instead of per-iteration basis.  I'm just going
to assume my not-yet-defined `GrepGrep` class just ends up with the results,
and save them to the model now:


```java
      // Fill in the model
      model._output._matches = Arrays.copyOf(gg._matches,gg._cnt);
      model._output._offsets = Arrays.copyOf(gg._offsets,gg._cnt);
  
      StringBuilder sb = new StringBuilder();
      sb.append("Grep: ").append("\n");
      sb.append(Arrays.toString(model._output._matches)).append("\n");
      sb.append(Arrays.toString(model._output._offsets)).append("\n");
      Log.info(sb);
```


### The GrepGrep Main Class

And now we need to figure what do in our main worker class.  This is the meat
of Grep - *for each byte*, search for a regex match.

Anything that starts out with the words "for each byte" when you have a few
gigabytes of text needs to run in-parallel and scale-out to have a chance of
completing fast - and this is exactly H2O is built for!  So let's write code
that runs scale-out for-each-byte... and the easiest way to do that is with an
H2O Map/Reduce job - an instance of MRTask.  `class GrepGrep` can be coded as
an inner class to the `GrepDriver` class:

```java
    private class GrepGrep extends MRTask<GrepGrep> {
      private final String _regex;
      // Outputs, hopefully not too big for once machine!
      String[] _matches;
      long  [] _offsets;
      int _cnt;
      GrepGrep( String regex ) { _regex = regex; }
  
      @Override public void map( Chunk chk ) {
        ...
      }
      @Override public void reduce( Histo h ) {
        ...
      }
    }
```

#### A Quick H<sub>2</sub>O Map/Reduce Diversion

This isn't your Hadoop-Daddy's Map/Reduce.  This is an in-memory super-fast
map-reduce... where "super-fast" generally means "memory bandwidth limited",
often 1000x faster than the usual hadoop-variant - MRTasks can often touch a
gigabyte of data in a millisecond, or a terabyte in a second (depending on how much
hardware is in your cluster - more hardware is faster for the same amount of
data!)

The `map()` call takes data in `Chunks` - where each `Chunk` is basically a
small array-like slice of the Big Data.  Data in Chunks is accessed with basic
`at0` and `set0` calls (vs accessing data in `Vecs` with `at` and `set`).  The
output of a `map()` is stored in the `GrepGrep` object itself, as a Plain Old
Java Object (POJO).  Each `map()` call has private access to its own fields and
`Chunks`, which implies there are lots of instances of `GrepGrep` objects
scattered all over the cluster (one such instance per `Chunk` of data...  well,
actually one instance per call to `map()`, but each map call is handed an
aligned set of Chunks, one per feature or column in the dataset).

Since there are lots of little GrepGreps running about, their results need to
be combined.  That's what `reduce` does - combine two `GrepGrep`s into one.
Typically, you can do this by adding similar fields together - often array
elements are added side-by-side, similar to a *saxpy* operation.

All code here is written in a single-threaded style, even as it runs in
parallel and distributed.  H2O handles all the synchronization issues.


### GrepGrep

Back to `class GrepGrep`, we create holders for the results, compile a JDK
regex `Pattern` object, then start looping over `Matches`.

```java
    @Override public void map( Chunk[] chks ) {
      _matches = new String[1]; // Result holders; will lazy expand
      _offsets = new long  [1];
      ByteSeq bs = new ByteSeq(chk,chk.nextChunk());
      Pattern p = Pattern.compile(_regex);
      // We already checked that this is an instance of a ByteVec, which means
      // all the Chunks contain raw text as byte arrays.
      Matcher m = p.matcher(bs);
      while( m.find() && m.start() < bs._bs0.length )
        add(bs.str(m.start(),m.end()),chk.start()+m.start());
      update(chk._len);         // Whole chunk of work, done all at once
    }
```

Note that I let the matches *end* in the second Chunk of data.  All matches
must start in the first Chunk of data; this prevents me from counting every
match twice (once in the first Chunk on a map call, once again in the second
Chunk on some other map call).  Ultimately I limit matches to one Chunk's worth
of raw text - about 4Megs for a single match - but they can span a Chunk
boundary.

I defined a simple class allowing a byte[] to be used as an instance of a
`CharSequence` to pass to the `Pattern.match` call, and a method to `add`
(accumulate) results.  Both are very simple.  `add` accumulates results in the
two result arrays, doubling their size as needed (to keep asymptotic costs
low):

```java
    private void add( String s, long off ) {
      if( _cnt == _matches.length ) {
        _matches = Arrays.copyOf(_matches,_cnt<<1);
        _offsets = Arrays.copyOf(_offsets,_cnt<<1);
      }
      _matches[_cnt  ] = s;
      _offsets[_cnt++] = off;
    }
```

The `class ByteSeq` wraps byte arrays in a simple interface implementation.
There's two special H2O properties at work here making this very efficient:
Always raw text data is stored as ... raw text data.  The `Chunk` wrappers used
to manipulate the big data are very thin wrappers over raw text - and the
underlying `byte[]`s are directly available.  They are also lazily loaded on
demand from the file system.  Editing the `byte[]`s can't be stopped with this
direct access, and is Bad Coding Style, and won't be reflected around the
cluster, so *Caveat Emptor*.  Nonetheless, pure read operations can get direct
access.

The other special H2O property is a little harder to explain, but just as
crucial - H2O does data-placement such that accessing the elements past the end
of one Chunk and into another guarantees that the next Chunk in line is
statistically very likely to be locally available.  If the data was psuedo
randomly distributed, you might expect that asking for a neighbor Chunk has
poor odds of being local (for a size N cluster, 1/N Chunks would be local).
Instead, something like 90% of next-Chunks are adjacent.  For Chunks are not
adjacent, you'll get a copy (from the ubiquitous DKV)- meaning that some
fraction of the data is replicated to cover the edge cases.  Basically, you get
to ignore the edge case, and have your `grep` run off the end of one Chunk and
into the next, for free.

```java
    private class ByteSeq implements CharSequence {
      private final byte _bs0[], _bs1[];
      ByteSeq( Chunk chk0, Chunk chk1 ) { _bs0 = chk0.getBytes(); _bs1 = chk1==null ? null : chk1.getBytes(); }
      @Override public char charAt(int idx ) { 
        return (char)(idx < _bs0.length ? _bs0[idx] : _bs1[idx-_bs0.length]); 
      }
      @Override public int length( ) { return _bs0.length+(_bs1==null?0:_bs1.length); }
      @Override public ByteSeq subSequence( int start, int end ) { throw H2O.unimpl(); }
      @Override public String toString() { throw H2O.unimpl(); }
      String str( int s, int e ) { return new String(_bs0,s,e-s); }
    }
```

And that ends the `map` call and its helps in the `GrepGrep` main work loop.

We also need a `reduce` to fold together the returned results; the `_mataches`
and the `_offsets` and the `_cnt`.  I'm using a `add` call again to make this
easier.  First I swap the larger set to the left, then I add the smaller set to
the larger, then I make sure all results go back into the `this` object.

```java
    @Override public void reduce( GrepGrep gg1 ) {
      GrepGrep gg0 = this;
      if( gg0._cnt < gg1._cnt ) { gg0 = gg1; gg1 = this; } // Larger result on left
      for( int i=0; i<gg1._cnt; i++ )
        gg0.add(gg1._matches[i], gg1._offsets[i]);
      if( gg0 != this ) {
        _matches = gg0._matches;
        _offsets = gg0._offsets;
        _cnt = gg0._cnt;
      }
    }
```

And that completes the Big Data portion of Grep.

------------------------------

## Running Grep

Back to the `class GrepTest`, I changed the file to something bigger -
`bigdata/laptop/text8.gz`.  You can get it via `gradlew syncBigdataLaptop`
which pulls down medium-large data from the Amazon cloud.  Since we didn't add
a GUnzip step, I manually unzipped `text8.txt` to get a 100Mb file.  GrepTest
looks for words with 5 or more letter-pairs in this file.

Running the GrepTest returns:

    11-15 22:12:58.489 192.168.1.11:54321    4740   FJ-0-7    INFO: Grep:
    11-15 22:12:58.489 192.168.1.11:54321    4740   FJ-0-7    INFO: [tttttttttt, ttttttcccc, mmmmmmmmmm, nnmmmmmmmm, mmmmmmmmmm, nnmmmmmmmm, mmmmmmmmmm, mmmmmmmmmm, mmmmmmmmmm, mmmmmmnnnn, tttttttttt, ssssssssss, ssssssssss, oorraaddoo, oonnookkee, oooooooooo, oooooooooo, wwwwwwwwww]
    11-15 22:12:58.489 192.168.1.11:54321    4740   FJ-0-7    INFO: [7113831, 7113936, 7114204, 7114223, 7114233, 7114287, 7114297, 7114307, 7114379, 7114774, 7114852, 24454164, 24454174, 38775393, 43764408, 81704383, 81704393, 52471050]

Takes about 5 seconds to run the regex `(?:(\\w)\\1){5}` on 100Mb; not too bad.
Looking at the answers I see some funny words there.  I checked with `grep -P
'(?:(\\w)\\1){5}' text8.txt` to see that I was getting the same answers - one
of the words is "racoonnookkeeper" - definitely a bit of a stretch!  `grep -P`
is somewhat faster than the JDK Pattern class; even though H2O was 4-way
parallel on my lap, the underlying JDK is too slow.

As an obvious extension, it would be nice to download one of the other Java
regex solutions I found on the web; most declared themselves to be vastly
faster than the JDK code.  Other cool hacks would include getting the line
number, and perhaps returning the entire matching line.

Good luck with your own H2O algorithm,<br>
*Cliff*
