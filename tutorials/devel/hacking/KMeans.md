# Hacking Algorithms into H<sub>2</sub>O: KMeans

> This is a presentation of hacking a simple algorithm into the new dev-friendly
branch of H2O, [h2o-dev](https://github.com/0xdata/h2o-dev/).

> This is one of three "Hacking Algorithms into H2O" tutorials.  All tutorials
start out the same - getting the h2o-dev code and building it.  They are the
same until the section titled [Building Our Algorithm: Copying from the
Example](#customizedStartsHere), and then the content is customized for each
algorithm.  This tutorial describes the algorithm [K-Means](http://en.wikipedia.org/wiki/K-means_clustering).


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
write the "glue" wrappers around algorithms and get the full GUI, R, REST and
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
  a K-Means algorithm.
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

Ok, that's a pretty big pile of output - but buried it in is some cool stuff we'll need to be able to pick out later, so let's break it down a little.

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
Because H2O-dev already has a KMeans algorithm, that name is
taken...  but we want our own. (Besides just doing it ourselves, there are some
cool extensions to KMeans we can add and sometimes it's easier to start from a
clean[er] slate).

So this algorithm is called KMeans2 (not too creative, I know).  I cloned the
main code and model from the `h2o-algos/src/main/java/hex/example/` directory
into `h2o-algos/src/main/java/hex/kmeans2/`, and also the test from
`h2o-algos/src/test/java/hex/example/` directory into
`h2o-algos/src/test/java/hex/kmeans2/`.

Then I copied the three GUI/REST files in `h2o-algos/src/main/java/hex/schemas`
with Example in the name (`ExampleHandler.java`, `ExampleModelV2.java`,
`ExampleV2`) to their `KMeans2*` variants.

I also copied the `h2o-algos/src/main/java/hex/api/ExampleBuilderHandler.java`
file to its `KMeans2` variant.  Finally I renamed the files **and** file contents
from `Example` to `KMeans2`.

I also dove into `h2o-app/src/main/java/water/H2OApp.java` and copied the two
`Example` lines and made **their** `KMeans2` variants.  Because I'm old-school,
I did this with a combination of shell hacking and Emacs; about 5 minutes all
told.

At this point, back in IDEAJ, I nagivated to `KMeans2Test.java`, right-clicked
debug-test `testIris` again - and was rewarded with my `KMeans2` clone running
a basic test.  Not a very good KMeans, but definitely a start.


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

In our case, K-Means is the algorithm - so that belongs in the
`KMeans2ModelBuilder.java` file, and the result is a set of clusters (a
model), so that belongs in the `KMeans2Model.java` file.

We also split Schemas from Models - to isolate slow-moving external APIs from
rapidly-moving *internal* APIs: as a Java dev you can hack the guts of K-Means
to your hearts content - including the inputs and outputs - as long as the
externally facing V2 schemas do not change.  If you want to report new stuff or
take new parameters, you can make a new V3 schema - which is not compatible
with V2 - for the new stuff.  Old external V2 users will not be affected by
your changes (you'll still have to make the correct mappings in the V2 schema
code from your V3 algorithm).

One other important hack: K-Means is an *unsupervised* algorithm - no training
data (no "response") tells it what the results "should" be.  So we need to hack
the word `Supervised` out of all the various class names it appears in.  After
this is done, your KMeans2Test probably fails to compile, because it is trying
to set the response column name in the test, and unsupervised models do not
get a response to train with.  Just delete the line for now:

```java
    parms._response_column = "class";
```

At this point we can run our test code again (still finding the max-per-column).


### The KMeans2 Model

The KMeans2 model, in the file `KMeans2Model.java`, should contain what we
expect out of K-Means: a set of clusters.  We'll represent a single cluster as
an N-dimensional point (an array of doubles).  For our K clusters, this will be:

```java
    public double _clusters[/*K*/][/*N*/]; // Our K clusters, each an N-dimensional point
```

Inside the `KMeans2Model` class, there is a class for the model's output:
`class KMeans2Output`.  We'll put our clusters there.  The various support
classes and files will make sure our model's output appears in the correct REST and
JSON responses and gets pretty-printed in the GUI.  There is also the
left-over `_maxs` array from the old Example code; we can delete that now.

To help assay the *goodness* our of model, we should also report some extra
facts about the training results.  The obvious thing to report is the Mean
Squared Error, or the average squared-error each training point has against its
chosen cluster:

```java
    public double _mse; // Mean Squared Error of the training data
```

And finally a quick report on the *effort* used to train: the number of
iterations training actually took.  K-Means runs in iterations, improving with
each iteration.  The algorithm typically stops when the model quits
improving; we report how many iterations it took here:

```java
    public int _iters; // Iterations we took
```

My final `KMeans2Output` class looks like:

```java
    public static class KMeans2Output extends Model.Output {
      public int _iters;      // Iterations executed
      public double _clusters[/*K*/][/*N*/]; // Our K clusters, each an N-dimensional point
      public double _mse;     // Mean Squared Error
      public KMeans2Output( KMeans2 b ) { super(b); }
      @Override public ModelCategory getModelCategory() { return Model.ModelCategory.Clustering; }
    }
```

Now, let's turn to the *input* to our model-building process.  These are stored
in the `class KMeans2Model.KMeans2Parameters`.  We already inherit an input
training dataset (returned with `train()`), possibly a validation dataset
(`valid()`), and some other helpers (e.g. which columns to ignore if we do
an expensive scoring step with each iteration).  For now, we can ignore
everything except the input dataset from `train()`.

However, we want some more parameters for K-Means: `K`, the number of clusters.
Define it next to the left-over `_max_iters` from the old Example code (which
we might as well keep since that's a useful stopping conditon for K-Means):

```java
        public int _K;
```

My final `KMeans2Parameters` class looks like:

```java
      public static class KMeans2Parameters extends Model.Parameters {
        public int _max_iters = 1000; // Max iterations
        public int _K = 0;
      }
```

A bit on field naming: I always use a leading underscore `_` before all
internal field names - it lets me know at a glance whether I'm looking at a
field name (stateful, can changed by other threads) or a function parameter
(functional, private).  The distinction becomes interesting when you are
sorting through large piles of code.  There's no other fundamental reason to
use (or not) the underscores.  *External* APIs, on the other hand, generally do
not care for leading underscores.  Our JSON output and REST URLs will strip the
underscores from these fields.

To make the GUI functional, I need to add my new K field to the external input
Schema in `h2o-algos/src/main/java/hex/schemas/KMeans2V2.java`:

```java
    public static final class KMeans2ParametersV2 extends ModelParametersSchema<KMeans2Model.KMeans2Parameters, KMeans2ParametersV2> {
      static public String[] own_fields = new String[] { "max_iters", "K"};
  
      // Input fields
      @API(help="Maximum training iterations.")  public int max_iters;
      @API(help="K")  public int K;
    }
```

And I need to add my result fields to the external output schema in
`h2o-algos/src/main/java/hex/schemas/KMeans2ModelV2.java`:

```java
    public static final class KMeans2ModelOutputV2 extends ModelOutputSchema<KMeans2Model.KMeans2Output, KMeans2ModelOutputV2> {
      // Output fields
      @API(help="Iterations executed") public int iters;
      @API(help="Cluster centers") public double clusters[/*K*/][/*N*/];
      @API(help="Mean Squared Error") public double mse;
```


### The KMeans2 Model Builder

Let's turn to the K-Means model builder, which includes some boilerplate we
inherited from the old Example code, and a place to put our real algorithm.
There is a basic `KMeans2` constructor which calls `init`:

```java
    public KMeans2( ... ) { super("KMeans2",parms); init(false); }
```

In this case, `init(false)` means "only do cheap stuff in `init`".  Init is
defined a little ways down and does basic (cheap) argument checking.
`init(false)` is called every time the mouse clicks in the GUI and is used to
let the front-end sanity parameters function as people type.  In this case "only do
cheap stuff" really means "only do stuff you don't mind waiting on while
clicking in the browser".  No running K-Means in the `init()` call!

Speaking of the `init()` call, the one we got from the old Example code limits
our `_max_iters` to between 1 and 10 million.  Let's add some lines to check
that K is sane:

```java
    if( _parms._K < 2 || _parms._K > 999999 )
      error("K","must be between 2 and a million");
```

Immediately when testing the code, I get a failure because the
`KMeans2Test.java` code does not set K and the default is zero.  I'll set K
to 3 in the test code:

```java
    parms._K = 3;
```

In the `KMeans2.java` file there is a `trainModel` call that is used when you
really want to start running K-Means (as opposed to just checking arguments).
In our case, the old boilerplate starts a `KMeans2Driver` in a background
thread.  Not required, but for any long-running algorithm, it is nice to have it
run in the background.  We'll get progress reports from the GUI (and from
REST/JSON) with the option to cancel the job, or inspect partial results as the
model builds.

The `class KMeans2Driver` holds the algorithmic meat.  The `compute2()` call
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
    _parms.lock_frames(KMeans2.this);
```

Locking prevents situations like accidentally deleting or loading a new dataset
with the same name while K-Means is running.  Like the `Scope.exit()` above, we
will unlock in `finally` block.  While it might be nice to use Java locking, or
even JDK 5.0 locks, we need a *distributed* lock, which is not provided by
JDK 5.0.  Note that H2O locks are strictly cooperative - we cannot
enforce locking at the JVM level like the JVM does.

Next, we make an instance of our model object (with no clusters yet) and place
it in the DKV, locked (e.g., to prevent another user from overwriting our
model-in-progress with an unrelated model).

```java
    model = new KMeans2Model(dest(), _parms, new KMeans2Model.KMeans2Output(KMeans2.this));
    model.delete_and_lock(_key);
```

Also, near the file bottom is a leftover `class Max` from the old Example code.
Might as well nuke it now.


### The KMeans2 Main Algorithm

Finally we get to where the Math is!

K-Means starts with some clusters, generally picked from the dataset
population, and then optimizes the cluster centers and cluster
assignments.  The easiest (but not the best!) way to pick clusters is just to
pick points at (pseudo) random.  So ahead of our iteration/main loop, let's pick
some clusters.

```java
    // Pseudo-random initial cluster selection
    Frame f = train(); // Input dataset
    double clusters[/*K*/][/*N*/] = model._output._clusters = new double[_parms._K][f.numCols()];
    Random R = new Random(); // Really awful RNG, we should pick a better one later
    for( int k=0; k<_parms._K; k++ ) {
      long row = Math.abs(R.nextLong() % f.numRows());
      for( int j=0; j<f.numCols(); j++ ) // Copy the point into our cluster
        clusters[k][j] = f.vecs()[j].at(row);
    }
    model.update(_key); // Update model in K/V store
```

My `KMeans2` now has a leftover loop from the old Example code running up to
some max iteration count.  This sounds like a good start to K-Means - we'll
need several stopping conditions, and max-iterations is one of them.

```java
    // Stop after enough iterations
    for( ; model._output._iters < _parms._max_iters; model._output._iters++ ) {
      ...
    }
```

Let's also stop if somebody clicks the "cancel" button in the GUI:

```java
    // Stop after enough iterations
    for( ; model._output._iters < _parms._max_iters; model._output._iters++ ) {
      if( !isRunning() ) break; // Stopped/cancelled
      ...
    }
```

I removed the "compute Max" code from the old Example code in the loop body.
Next up, I see code to record any new **model** (e.g. clusters, mse), and save
the results back into the DKV, bump the progress bar, and log a little bit of
progress:


```java
      // Fill in the model
      model._output._clusters = ????? // we need to figure these out
      model.update(_key); // Update model in K/V store
      update(1);          // One unit of work in the GUI progress bar

      StringBuilder sb = new StringBuilder();
      sb.append("KMeans2: iter: ").append(model._output._iters);
      Log.info(sb);
```


### The KMeans2 Main Loop

And now we need to figure what do in our main loop.  Somewhere between the
loop-top-isRunning check and the `model.update()` call, we need to compute
something to update our model with!  This is the meat of K-Means - *for each
point*, assign it to the nearest cluster center, then compute new cluster
centers from the assigned points, and iterate until the clusters quit moving.

Anything that starts out with the words "for each point" when you have a billion
points needs to run in-parallel and scale-out to have a chance of completing
fast - and this is exactly H2O is built for!  So let's write code that runs
scale-out for-each-point... and the easiest way to do that is with an H2O
Map/Reduce job - an instance of MRTask.  For K-Means, this is an instance of
Lloyd's basic algorithm.  We'll call it from the main-loop like this, and
define it below (extra lines included so you can see how it fits):

```java
      if( !isRunning() ) break; // Stopped/cancelled

      Lloyds ll = new Lloyds(clusters).doAll(f);
      clusters = model._output._clusters = ArrayUtils.div(ll._sums,ll._rows);
      model._output._mse = ll._se/f.numRows();

      // Fill in the model
      model.update(_key); // Update model in K/V store
      update(1);          // One unit of work

      StringBuilder sb = new StringBuilder();
      sb.append("KMeans2: iter: ").append(model._output._iters).append(" MSE=").append(model._output._mse).append(" ROWS=").append(Arrays.toString(_rows);
      Log.info(sb);
```

Let's also add a stopping condition if the clusters stop moving:

```java
    // Stop after enough iterations
    double last_mse = Double.MAX_VALUE; // MSE from prior iteration
    for( ; model._output._iters < _parms._max_iters; model._output._iters++ ) {
      if( !isRunning() ) break; // Stopped/cancelled

      Lloyds ll = new Lloyds(clusters).doAll(f);
      clusters = model._output._clusters = ArrayUtils.div(ll._sums,ll._rows);
      model._output._mse = ll._se/f.numRows();

      // Fill in the model
      model.update(_key); // Update model in K/V store
      update(1);          // One unit of work

      StringBuilder sb = new StringBuilder();
      sb.append("KMeans2: iter: ").append(model._output._iters).append(" MSE=").append(model._output._mse).append(" ROWS=").append(Arrays.toString(_rows);
      Log.info(sb);

      // Also stop if the model stops improving (if MSE stops dropping very much)
      double improv = (last_mse-model._output._mse) / model._output._mse;
      if( improv < 1e-4 ) break;
      last_mse = model._output._mse;
    }
```

Basically, we just called some not-yet-defined `Lloyds` code, computed some
cluster centers by computing the average point from the points in the new
cluster, and copied the results into our model.  I also printed out the Mean
Squared Error and row counts, so we can watch the progress over time.  Finally
we end with another stopping condition: stop if the latest model is really not
much better than the last model.  Now `class Lloyds` can be coded as an inner
class to the `KMeans2Driver` class:

```java
    class Lloyds extends MRTask<Lloyds> {
      private final double[/*K*/][/*N*/] _clusters; // Old cluster
      private double[/*K*/][/*N*/] _sums;  // Sum of points in new cluster
      private long[/*K*/] _rows;           // Number of points in new cluster
      private double _se;                  // Squared Error
      Lloyds( double clusters[][] ) { _clusters = clusters; }
      @Override public void map( Chunk[] chks ) {
        ...
      }
      @Override public void reduce( Lloyds ll ) {
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
output of a `map()` is stored in the `Lloyds` object itself, as a Plain Olde
Java Object (POJO).  Each `map()` call has private access to its own fields and
`Chunks`, which implies there are lots of instances of `Lloyds` objects
scattered all over the cluster (one such instance per `Chunk` of data...
well, actually one instance per call to `map()`, but each map call is handed an
aligned set of Chunks, one per feature or column in the dataset).

Since there are lots of little Lloyds running about, their results need to be
combined.  That's what `reduce` does - combine two `Lloyds` into one.
Typically, you can do this by adding similar fields together - often array
elements are added side-by-side, similar to a *saxpy* operation.

All code here is written in a single-threaded style, even as it runs in
parallel and distributed.  H2O handles all the synchronization
issues.


#### A Quick Helper

A common op is to compute the distance between two points.  We'll compute
it as the squared Euclidean distance (squared so as to avoid an expensive
square-root operation):

```java
    static double distance( double[] ds0, double[] ds1 ) {
      double sum=0;
      for( int i=0; i<ds0.length; i++ )
        sum += (ds0[i]-ds1[i])*(ds0[i]-ds1[i]);
      return sum;
    }
```


### Lloyd's

Back to Lloyds, we loop over the `Chunk[]` of data handed the `map` call by
moving it as a `double[]` for easy handling:

```java
    @Override public void map( Chunk[] chks ) {
      double[] ds = new double[chks.length];
      for( int row=0; row<chks[0]._len; row++ ) {
        for( int i=0; i<ds.length; i++ ) ds[i] = chks[i].at0(row);
        ...
      }
    }
```

Then we need to find the nearest cluster center:

```java
        for( int i=0; i<ds.length; i++ ) ds[i] = chks[i].at0(row);
        // Find distance to cluster 0
        int nearest=0;
        double dist = distance(ds,_clusters[nearest]);
        // Find nearest cluster, and its distance
        for( int k=1; k<_parms._K; k++ ) {
          double dist2 = distance(ds,_clusters[k]);
          if( dist2 < dist ) { dist = dist2; nearest = k; }
        }
        ...
```

And then add the point into our growing pile of points in the new clusters
we're building:

```java
          if( dist2 < dist ) { dist = dist2; nearest = k; }
        }
        // Add the point into the chosen cluster
        ArrayUtils.add(_sums[nearest],ds);
        _rows[nearest]++;
        // Accumulate squared-error (which is just squared-distance)
        _se += dist;
```

And that ends the `map` call and the Lloyds main work loop.  To recap, here it
is all at once:

```java
    @Override public void map( Chunk[] chks ) {
      double[] ds = new double[chks.length];
      for( int row=0; row<chks[0]._len; row++ ) {
        for( int i=0; i<ds.length; i++ ) ds[i] = chks[i].at0(row);
        // Find distance to cluster 0
        int nearest=0;
        double dist = distance(ds,_clusters[nearest]);
        // Find nearest cluster, and its distance
        for( int k=1; k<_parms._K; k++ ) {
          double dist2 = distance(ds,_clusters[k]);
          if( dist2 < dist ) { dist = dist2; nearest = k; }
        }
        // Add the point into the chosen cluster
        ArrayUtils.add(_sums[nearest],ds);
        _rows[nearest]++;
        // Accumulate squared-error (which is just squared-distance)
        _se += dist;
      }
    }
```

The `reduce` needs to fold together the returned results; the `_sums`, the
`_rows` and the `_se`:

```java
    @Override public void reduce( Lloyds ll ) {
      ArrayUtils.add(_sums,ll._sums);
      ArrayUtils.add(_rows,ll._rows);
      _se += ll._se;
    }
```

And that completes KMeans2!

------------------------------

## Running K-Means

Running the KMeans2Test returns:

    11-09 16:47:36.609 192.168.1.2:54321     3036   FJ-0-7    INFO: KMeans2: iter: 0 1.9077333333333335 ROWS=[66, 34, 50]
    11-09 16:47:36.610 192.168.1.2:54321     3036   FJ-0-7    INFO: KMeans2: iter: 1 0.6794683457919871 ROWS=[60, 40, 50]
    11-09 16:47:36.611 192.168.1.2:54321     3036   FJ-0-7    INFO: KMeans2: iter: 2 0.604730388888889 ROWS=[54, 46, 50]
    11-09 16:47:36.613 192.168.1.2:54321     3036   FJ-0-7    INFO: KMeans2: iter: 3 0.5870257150458589 ROWS=[51, 49, 50]
    11-09 16:47:36.614 192.168.1.2:54321     3036   FJ-0-7    INFO: KMeans2: iter: 4 0.5828039837094235 ROWS=[50, 50, 50]
    11-09 16:47:36.615 192.168.1.2:54321     3036   FJ-0-7    INFO: KMeans2: iter: 5 0.5823599999999998 ROWS=[50, 50, 50]
    11-09 16:47:36.616 192.168.1.2:54321     3036   FJ-0-7    INFO: KMeans2: iter: 6 0.5823599999999998 ROWS=[50, 50, 50]
    11-09 16:47:36.618 192.168.1.2:54321     3036   FJ-0-7    INFO: KMeans2: iter: 7 0.5823599999999998 ROWS=[50, 50, 50]
    11-09 16:47:36.619 192.168.1.2:54321     3036   FJ-0-7    INFO: KMeans2: iter: 8 0.5823599999999998 ROWS=[50, 50, 50]
    11-09 16:47:36.621 192.168.1.2:54321     3036   FJ-0-7    INFO: KMeans2: iter: 9 0.5823599999999998 ROWS=[50, 50, 50]

You can see the Mean Squared Error dropping over time, and the clusters stabilizing.

At this point there are a zillion ways we could take this K-Means:

- Report *MSE* on the validation set
- Report MSE per-cluster (some clusters will be 'tighter' than others)
- Run K-Means with different seeds, which will likely build different
  clusters - and report the best cluster, or even sort and group them by MSE.
- Handle categoricals (e.g. compute Manhattan distance instead of Euclidean)
- Normalize the data (optionally, on a flag).  Without normalization features,
  larger absolute values will have larger distances (errors) and will get
  priority of other features.
- Aggressively split high-variance clusters to see if we can get K-Means out of
  a local minima
- Handle clusters that "run dry" (zero rows), possibly by splitting the point
  with the most error/distance out from its cluster to make a new one.

I'm sure you can think of lots more ways to extend K-Means!

Good luck with your own H2O algorithm,<br>
Cliff
