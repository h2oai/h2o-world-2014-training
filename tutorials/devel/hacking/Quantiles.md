# Hacking Algorithms into H<sub>2</sub>O: Quantiles

> This is a presentation of hacking a simple algorithm into the new dev-friendly
branch of H2O, [h2o-dev](https://github.com/0xdata/h2o-dev/).

> This is one of three "Hacking Algorithms into H2O" tutorials.  All three tutorials
start out the same: getting the h2o-dev code and building it.  They are the
same until the section titled [Building Our Algorithm: Copying from the
Example](#customizedStartsHere), and then the content is customized for each
algorithm.  This tutorial describes computing [Quantiles](http://en.wikipedia.org/wiki/Quantile).


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
  a quantiles algorithm.
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

We want to compute Quantiles, so let's call the code `quantile`.  I cloned the
main code and model from the `h2o-algos/src/main/java/hex/example/` directory
into `h2o-algos/src/main/java/hex/quantile/`, and the test from
`h2o-algos/src/test/java/hex/example/` directory into
`h2o-algos/src/test/java/hex/quantile/`.

Then I copied the three GUI/REST files in `h2o-algos/src/main/java/hex/schemas`
with Example in the name (`ExampleHandler.java`, `ExampleModelV2.java`,
`ExampleV2`) to their `Quantile*` variants.

I also copied the `h2o-algos/src/main/java/hex/api/ExampleBuilderHandler.java`
file to its `Quantile` variant.  Finally, I renamed the files **and** file contents
from `Example` to `Quantile`.

I also dove into `h2o-app/src/main/java/water/H2OApp.java` and copied the two
`Example` lines and made **their** `Quantile` variants.  Because I'm old-school,
I did this with a combination of shell hacking and Emacs; about 5 minutes all
told.

At this point, back in IDEAJ, I nagivated to `QuantileTest.java`, right-clicked
debug-test `testIris` again - and was rewarded with my `Quantile` clone running
a basic test.  Not a very good Quantile, but definitely a start.


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

In our case, we want quantiles as a result - a mathematical representation of
the world - so that belongs in the `QuantileModel.java` file.  The algorithm
to compute quantiles belongs in the `QuantileModelBuilder.java` file.

We also split Schemas from Models to isolate slow-moving external APIs from
rapidly-moving *internal* APIs. As a Java dev, you can hack the guts of Quantile
to your heart's content, including the inputs and outputs, as long as the
externally facing V2 schemas do not change.  If you want to report new stuff or
take new parameters, you can make a new V3 schema (which is not compatible
with V2) for the new stuff.  Old external V2 users will not be affected by
your changes - you'll still have to make the correct mappings in the V2 schema
code from your V3 algorithm.

One other important hack: quantiles is an *unsupervised* algorithm - no training
data (no "response") tells it what the results "should" be.  So we need to hack
the word `Supervised` out of all the various class names it appears in.  After
this is done, your QuantileTest probably fails to compile, because it is trying
to set the response column name in the test, and unsupervised models do not
get a response to train with.  Just delete the line for now:

```java
    parms._response_column = "class";
```

At this point, we can run our test code again (still finding the max-per-column).


### The Quantile Model

The Quantile model, in the file `QuantileModel.java`, should contain what we
expect out of quantiles: the quantile value - a single `double`.  Usually people
request a set of Q probabilities (e.g., the 1%, 5%, 25% and 50% probabilities),
so we'll report a `double[/*Q*/]` of quantiles.  Also, we'll report them for
all N columns in the dataset, so it will really be a `double[/*N*/][/*Q*/]`.  For our Q
probabilities, this will be:

```java
    public double _quantiles[/*N*/][/*Q*/]; // Our N columns, Q quantiles reported
```

Inside the `QuantileModel` class, there is a class for the model's output:
`class QuantileOutput`.  We'll put our quantiles there.  The various support
classes and files will make sure our model's output appears in the correct REST &
JSON responses, and gets pretty-printed in the GUI.  There is also the
left-over `_maxs` array from the old Example code; we can delete that now.

And finally a quick report on the *effort* used to build the model: the number
of iterations we actually took.  Our quantiles will run in iterations,
improving with each iteration until we get the exact answer.  I'll describe the
algorithm in detail below, but it's basically an aggressive
[radix sort](http://en.wikipedia.org/wiki/Radix_sort).

My final `QuantileOutput` class looks like:

```java
    public static class QuantileOutput extends Model.Output {
      public int _iters;      // Iterations executed
      public double _quantiles[/*N*/][/*Q*/]; // Our N columns, Q quantiles reported
      public QuantileOutput( Quantile b ) { super(b); }
      @Override public ModelCategory getModelCategory() { return Model.ModelCategory.Unknown; }
    }
```

Now, let's turn to the *input* for our model-building process.  These are stored
in the `class QuantileModel.QuantileParameters`.  We already inherit an input
training dataset (returned with `train()`), and some other helpers (e.g. which
columns to ignore if we do an expensive scoring step with each iteration).  For
now, we can ignore everything except the input dataset from `train()`.

However, we want some more parameters for quantiles: the set of probabilities.
Let's also put in some default probabilities (the GUI & REST/JSON layer will let
these be overridden, but it's nice to have some sane defaults).  Define it next
to the left-over `_max_iters` from the old Example code (which we might as well
also nuke):

```java
        // Set of probabilities to compute
        public double _probs[/*Q*/] = new double[]{0.01,0.05,0.10,0.25,0.333,0.50,0.667,0.90,0.95,0.99};
```

My final `QuantileParameters` class looks like:

```java
      public static class QuantileParameters extends Model.Parameters {
        // Set of probabilities to compute
        public double _probs[/*Q*/] = new double[]{0.01,0.05,0.10,0.25,0.333,0.50,0.667,0.90,0.95,0.99};
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

To make the GUI functional, I need to add my new probabilities field to the external schema
in `h2o-algos/src/main/java/hex/schemas/QuantileV2.java`:

```java
    public static final class QuantileParametersV2 extends ModelParametersSchema<QuantileModel.QuantileParameters, QuantileParametersV2> {
      static public String[] own_fields = new String[] {"probs"};
  
      // Input fields
      @API(help="Probabilities for quantiles")  public double probs[];
    }
```

And I need to add my result fields to the external output schema in
`h2o-algos/src/main/java/hex/schemas/QuantileModelV2.java`:

```java
    public static final class QuantileModelOutputV2 extends ModelOutputSchema<QuantileModel.QuantileOutput, QuantileModelOutputV2> {
      // Output fields
      @API(help="Iterations executed") public int iters;
      @API(help="Quantiles per column") public double quantiles[/*Q*/][/*N*/];
```


### The Quantile Model Builder

Let's turn to the Quantile model builder, which includes some boilerplate we
inherited from the old Example code, and a place to put our real algorithm.
There is a basic `Quantile` constructor which calls `init`:

```java
    public Quantile( ... ) { super("Quantile",parms); init(false); }
```

In this case, `init(false)` means "only do cheap stuff in `init`".  Init is
defined a little ways down and does basic (cheap) argument checking.
`init(false)` is called every time the mouse clicks in the GUI and is used to
let the front-end sanity parameters function as people type.  In this case
"only do cheap stuff" really means "only do stuff you don't mind waiting on
while clicking in the browser".  No computing quantiles in the `init()` call!

Speaking of the `init()` call, the one we got from the old Example code limits
sanity checks the now-deleted `_max_iters`.  Let's add some lines to check that
our `_probs` are sane:

```java
  for( double p : _parms._probs )
    if( p < 0.0 || p > 1.0 )
      error("probs","Probabilities must be between 0 and 1 ");
```

In the `Quantile.java` file there is a `trainModel` call that is used when you
really want to start running quantiles (as opposed to just checking arguments).
In our case, the old boilerplate starts a `QuantileDriver` in a background
thread.  Not required, but for any long-running algorithm, it is nice to have it
run in the background.  We'll get progress reports from the GUI (and from
REST/JSON) with the option to cancel the job, or inspect partial results as the
model builds.

The `class QuantileDriver` holds the algorithmic meat.  The `compute2()` call
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
    _parms.lock_frames(Quantile.this);
```

Locking prevents situations like accidentally deleting or loading a new dataset
with the same name while quantiles is running.  Like the `Scope.exit()` above,
we will unlock in the `finally` block.  While it might be nice to use Java locking,
or even JDK 5.0 locks, we need a *distributed* lock, which is not provided by
JDK 5.0.  Note that H2O locks are strictly cooperative - we cannot
enforce locking at the JVM level like the JVM does.

Next, we make an instance of our model object (with no clusters yet) and place
it in the DKV, locked (e.g., to prevent another user from overwriting our
model-in-progress with an unrelated model).

```java
    model = new QuantileModel(dest(), _parms, new QuantileModel.QuantileOutput(Quantile.this));
    model.delete_and_lock(_key);
```

Also, near the file bottom is a leftover `class Max` from the old Example code.
Might as well nuke it now.


### The Quantile Main Algorithm

Finally we get to where the Math is!

Quantiles can be computed in a variety of ways, but the most common starting
point is to sort the elements - then, finding the Nth element is easy.  Alas,
sorting large datasets is expensive.  Also, sorting provides a total order on
the data, which is overkill for what we need.  Instead, we'll do a couple of
rounds of a radix-sort, refining our solution with each iteration until we get
the exact answer.  The key metric in a radix sort is the number of bins used;
we want all our bins to fit in cache, probably even L1 cache, so we'll start
with limiting ourselves to 1024 bins.

Given a histogram / radix-sort of 1024 bins on a billion rows, each bin will
represent approximately 1 million rows.  We then pick the bin holding the Nth
element, and re-bin / re-histogram / re-radix-sort another 1024 bins refining
the bin holding the Nth element.  We expect this bin to hold about 1000
elements.  Finding the Nth element in a billion rows then probably takes 3 or 4
passes (worst case is sorta bad: 100 passes), and each pass will be really fast.

Basically, we're gonna fake a sort - we'll end up with the elements for the
exact row numbers we want for each probability (and not all the other row
numbers).  E.g., if the probability of 0.4567 on a billion row dataset needs
the element (in sorted order) for row 456,700,000 - we'll get it (this element
is not related to the unsorted row number 456,700,000).

Besides a classic histogram (element counts per bucket), we will also need an
actual value - if there is a unique one.  This is always true if we only have one
element in a bucket, but it might also be true if we have a long run of the
same value (e.g., lots of the year 2014's in our dataset).

My `Quantile` now has a leftover loop from the old Example code running up to
some max iteration count.  Let's nuke it and just run a loop over all the
dataset columns.

```java
    // Run the main Quantile Loop
    Vec vecs[] = train().vecs();
    for( int n=0; n<vecs.length; n++ ) {
      ...
    }
```

Let's also stop if somebody clicks the "cancel" button in the GUI:

```java
    for( int n=0; n<vecs.length; n++ ) {
      if( !isRunning() ) return; // Stopped/cancelled
      ...
    }
```

I removed the "compute Max" code from the old Example code in the loop body.
Next up, I see code to record any new **model** (e.g. quantiles), and save
the results back into the DKV, bump the progress bar, and log a little bit of
progress:


```java
      // Update the model
      model._output._quantiles = ????? // we need to figure these out
      model._output._iters++; // One iter per-prob-per-column
      model.update(_key); // Update model in K/V store
      update(1);          // One unit of work in the GUI progress bar

      StringBuilder sb = new StringBuilder();
      sb.append("Quantile: iter: ").append(model._output._iters);
      Log.info(sb);
```


### The Quantile Main Loop

And now we need to figure what do in our main loop.  Somewhere between the
loop-top-isRunning check and the `model.update()` call, we need to compute
something to update our model with!  This is the meat of Quantile - *for each
point*, bin it - build a histogram.  With the histogram in hand, we see if we
can compute the exact quantile, if we cannot and then build a new refined
histogram from the bounds computed in the prior histogram.

Anything that starts out with the words "for each point" when you have a billion
points needs to run in-parallel and scale-out to have a chance of completing
fast - and this is exactly H2O is built for!  So let's write code that runs
scale-out for-each-point... and the easiest way to do that is with an H2O
Map/Reduce job - an instance of MRTask.  For Quantile, this is an instance of
a histogram.  We'll call it from the main-loop like this, and
define it below (extra lines included so you can see how it fits):

```java
      if( !isRunning() ) return; // Stopped/cancelled
      Vec vec = vecs[n];
      // Compute top-level histogram
      Histo h1 = new Histo(/*bounds for the full Vec*/).doAll(vec);  // Need to figure this out???

      // For each probability, see if we have it exactly - or else run
      // passes until we do.
      for( int p = 0; p < _parms._probs.length; p++ ) {
        double prob = _parms._probs[p];
        Histo h = h1;  // Start from the first global histogram

        while( h.not_have_exact_quantile??? )  // Need to figure this out???
          h = h.refine_histogram????           // Need to figure this out???

        // Update the model
        model._output._iters++; // One iter per-prob-per-column
        model.update(_key); // Update model in K/V store
        update(1);          // One unit of work
      }
      StringBuilder sb = new StringBuilder();
      sb.append("Quantile: iter: ").append(model._output._iters).append(" Qs=").append(Arrays.toString(model._output._quantiles[n]));
      Log.info(sb);
```

Basically, we just called some not-yet-defined `Histo` code on the entire `Vec`
(column) of data, then looped over each probability.  If we can compute the
quantile exactly for the probability, great!  If not, we build and run another
histogram over a refined range, repeating until we can compute the exact
histogram.  I also printed out the quantiles per `Vec`, so we can watch the
progress over time.  Now `class Histo` can be coded as an inner class to the
`QuantileDriver` class:

```java
    class Histo extends MRTask<Histo> {
      private static final int NBINS=1024; // Default bin count
      private final int _nbins;            // Actual  bin count
      private final double _lb;            // Lower bound of bin[0]
      private final double _step;          // Step-size per-bin
      private final long _start_row;       // Starting row number for this lower-bound
      private final long _nrows;           // Total datasets rows
  
      // Big Data output result
      long   _bins [/*nbins*/]; // Rows in each bin
      double _elems[/*nbins*/]; // Unique element, or NaN if not unique
  
      private Histo( double lb, double ub, long start_row, long nrows  ) { 
        _nbins = NBINS;
        _lb = lb;
        _step = (ub-lb)/_nbins;
        _start_row = start_row;
        _nrows = nrows;
      }

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
output of a `map()` is stored in the `Histo` object itself, as a Plain Old
Java Object (POJO).  Each `map()` call has private access to its own fields and
`Chunks`, which implies there are lots of instances of `Histo` objects
scattered all over the cluster (one such instance per `Chunk` of data...
well, actually one instance per call to `map()`, but each map call is handed an
aligned set of Chunks, one per feature or column in the dataset).

Since there are lots of little Histos running about, their results need to be
combined.  That's what `reduce` does - combine two `Histo`s into one.
Typically, you can do this by adding similar fields together - often array
elements are added side-by-side, similar to a *saxpy* operation.

All code here is written in a single-threaded style, even as it runs in
parallel and distributed.  H2O handles all the synchronization
issues.


### Histogram

Back to `class Histo`, we create arrays to hold our results and loop over the
data:

```java
    @Override public void map( Chunk[] chks ) {
      long   bins [] = _bins =new long  [_nbins];
      double elems[] = _elems=new double[_nbins];
      for( int row=0; row<chk._len; row++ ) {
        double d = chk.at0(row);
        ....
      }        
    }
```

Then we need to find the correct bin (simple linear interpolation).  If the bin
is in-range, increment the bin count.  Note that if a value is *missing*, it
will represented as a NaN, then the computation of `idx` will be a NaN and the
range test will fail and no bin will be incremented.

```java
      for( int row=0; row<chk._len; row++ ) {
        double d = chk.at0(row);
        double idx = (d-_lb)/_step;
        if( !(0.0 <= idx && idx < bins.length) ) continue;
        int i = (int)idx;
        ...
        bins[i]++;
      }
```

Also gather a unique element in the bin, if there is a unique element (otherwise, use NaN).

```java
        int i = (int)idx;
        if( bins[i]==0 ) elems[i] = d; // Capture unique value
        else if( !Double.isNaN(elems[i]) && elems[i]!=d ) 
          elems[i] = Double.NaN; // Not unique
        bins[i]++;               // Bump row counts
```

And that ends the `map` call and the `Histo` main work loop.  To recap, here it
is all at once:

```java
    @Override public void map( Chunk chk ) {
      long   bins [] = _bins =new long  [_nbins];
      double elems[] = _elems=new double[_nbins];
      for( int row=0; row<chk._len; row++ ) {
        double d = chk.at0(row);
        double idx = (d-_lb)/_step;
        if( !(0.0 <= idx && idx < bins.length) ) continue;
        int i = (int)idx;
        if( bins[i]==0 ) elems[i] = d; // Capture unique value
        else if( !Double.isNaN(elems[i]) && elems[i]!=d ) 
          elems[i] = Double.NaN; // Not unique
        bins[i]++;               // Bump row counts
      }        
    }
```

The `reduce` needs to fold together the returned results; the `_elems` and the
`_bins`.  It's a bit tricky for the unique elements - either the left Histo or
the right Histo might have zero, one, or many elements - and if they both have a
unique element, it might not be the same unique element.

```java
    @Override public void reduce( Histo h ) { 
      for( int i=0; i<_nbins; i++ ) // Keep unique elements
        if( _bins[i]== 0 ) _elems[i] = h._elems[i]; // Left had none, so keep right unique
        else if( h._bins[i] > 0 && _elems[i] != h._elems[i] )
          _elems[i] = Double.NaN; // Left & right both had elements, but not equal
      ArrayUtils.add(_bins,h._bins);
    }
```

And that completes the Big Data portion of Quantile.


### From Histogram to Quantile

Now we get to the nit-picky part of Quantiles.  This isn't Big Data, but it is
Math.  Gotta get it right!  We have this code we need to figure out:

```java
        while( h.not_have_exact_quantile??? )  // Need to figure this out???
          h = h.refine_histogram????           // Need to figure this out???
```

Let's make a function to return the exact Quantile (if we can compute it, or use
NaN otherwise).  We'll call it like this, capturing the quantile in the model
output as we test for NaN:

```java
        while( Double.isNaN(model._output._quantiles[n][p] = h.findQuantile(prob)) )
          h = h.refine_histogram????           // Need to figure this out???
```

For the `findQuantile` function we will:
- Find the fractional (sorted) row number for the given probability.
- Find the lower actual integral row number.  If the probability evenly divides
  the dataset, then we want the element for the sorted row.  If not, we need
  both elements on either side of the fractional row number.
- Find the histogram bin for the lower row.
- Find the unique element for this bin, or return a NaN (need another
  refinement pass)
- Repeat for the higher row number: find the bin, find the unique element or
  return NaN.
- With the two values spanning the desired probability in-hand, compute the
  quantile.  We'll use R's Type-7 linear interpolation, but we could just as
  well use any of the other types.

Here's my `findQuantile` code:

```java
    double findQuantile( double prob ) {
      double p2 = prob*(_nrows-1); // Desired fractional row number for this probability
      long r2 = (long)p2;       // Lower integral row number
      int loidx = findBin(r2);  // Find bin holding low value
      double lo = (loidx == _nbins) ? binEdge(_nbins) : _elems[loidx];
      if( Double.isNaN(lo) ) return Double.NaN; // Needs another pass to refine lo
      if( r2==p2 ) return lo;   // Exact row number?  Then quantile is exact

      long r3 = r2+1;           // Upper integral row number
      int hiidx = findBin(r3);  // Find bin holding high value
      double hi = (hiidx == _nbins) ? binEdge(_nbins) : _elems[hiidx];
      if( Double.isNaN(hi) ) return Double.NaN; // Needs another pass to refine hi
      return computeQuantile(lo,hi,r2,_nrows,prob);
    }
```

And a couple of simple helper functions:

```java
    private double binEdge( int idx ) { return _lb+_step*idx; }

    // bin for row; can be _nbins if just off the end (normally expect 0 to nbins-1)
    private int findBin( long row ) {
      long sum = _start_row;
      for( int i=0; i<_nbins; i++ )
        if( row < (sum += _bins[i]) )
          return i;
      return _nbins;
    }
```

Finally the computeQuantiles call:

```java
    static double computeQuantile( double lo, double hi, long row, long nrows, double prob ) {
      if( lo==hi ) return lo;     // Equal; pick either
      // Unequal, linear interpolation
      double plo = (double)(row+0)/(nrows-1); // Note that row numbers are inclusive on the end point, means we need a -1
      double phi = (double)(row+1)/(nrows-1); // Passed in the row number for the low value, high is the next row, so +1
      assert plo <= prob && prob < phi;
      return lo + (hi-lo)*(prob-plo)/(phi-plo); // Classic linear interpolation
    }
```

### Refining a Histogram

Now we need to define how to refine a Histogram.  Let's just admit it needs a
Big Data pass up front and call the `doAll()` in the driver loop directly:

```java
        while( Double.isNaN(model._output._quantiles[n][p] = h.findQuantile(prob)) )
          h = h.refinePass(prob).doAll(vec); // Full pass at higher resolution
```

Then the `refinePass` call needs to make a new Histogram from the old one, with
refined endpoints.  The original Histogram had endpoints of `vec.min()` and
`vec.max()`, but here we'll use endpoints from the same bins that
`findQuantiles` uses.

```java
    Histo refinePass( double prob ) {
      double prow = prob*(_nrows-1); // Desired fractional row number for this probability
      long lorow = (long)prow;       // Lower integral row number
      int loidx = findBin(lorow);    // Find bin holding low value
      // If loidx is the last bin, then high must be also the last bin - and we
      // have an exact quantile (equal to the high bin) and we didn't need
      // another refinement pass
      assert loidx < _nbins;
      double lo = binEdge(loidx); // Lower end of range to explore
      // If probability does not hit an exact row, we need the elements on
      // either side - so the next row up from the low row
      long hirow = lorow==prow ? lorow : lorow+1;
      int hiidx = findBin(hirow);    // Find bin holding high value
      // Upper end of range to explore - except at the very high end cap
      double hi = hiidx==_nbins ? binEdge(_nbins) : binEdge(hiidx+1);

      long sum = _start_row; // Compute adjusted starting row for this histogram
      for( int i=0; i<loidx; i++ )
        sum += _bins[i];
      return new Histo(lo,hi,sum,_nrows);
    }
```


------------------------------

## Running Quantile

Running the QuantileTest returns:

    11-13 12:19:04.179 172.16.2.47:54321     1940   FJ-0-7    INFO: Quantile: iter: 11 Qs=[4.4, 4.6000000000000005, 4.800000000000001, 5.1000000000000005, 5.4, 5.800000000000001, 6.300000000000001, 6.4, 6.9, 7.255000000000001, 7.7]
    11-13 12:19:04.183 172.16.2.47:54321     1940   FJ-0-7    INFO: Quantile: iter: 22 Qs=[2.2, 2.345, 2.5, 2.8000000000000003, 2.9000000000000004, 3.0, 3.2, 3.3000000000000003, 3.61, 3.8000000000000003, 4.151]
    11-13 12:19:04.187 172.16.2.47:54321     1940   FJ-0-7    INFO: Quantile: iter: 33 Qs=[1.1490000000000002, 1.3, 1.4000000000000001, 1.6, 2.5787, 4.35, 4.9, 5.1000000000000005, 5.800000000000001, 6.1000000000000005, 6.7]
    11-13 12:19:04.191 172.16.2.47:54321     1940   FJ-0-7    INFO: Quantile: iter: 44 Qs=[0.1, 0.2, 0.2, 0.30000000000000004, 0.8468, 1.3, 1.6, 1.8, 2.2, 2.3000000000000003, 2.5]
    11-13 12:19:04.194 172.16.2.47:54321     1940   FJ-0-7    INFO: Quantile: iter: 55 Qs=[0.0, 0.0, 0.0, 0.0, 0.6169999999999999, 1.0, 1.383, 2.0, 2.0, 2.0, 2.0]

You can see the Quantiles-per-column (and there are 11 of them by default, so
the iteration printout bumps by 11's).  I checked these numbers vs R's
default Type 7 quantiles for the `iris` dataset and got the same numbers.

Iris is too small to trigger the refinement pass, so I also tested on
[covtype.data](https://archive.ics.uci.edu/ml/datasets/Covertype) - an old
forest covertype dataset with about a half-million rows.  Took about 0.7
seconds on my laptop to compute 11 quantiles exactly, on 55 columns and 581000
rows.

Good luck with your own H2O algorithm,<br>
Cliff
