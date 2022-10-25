<!DOCTYPE html>
<html lang="en">
<head>
  <title>Database</title>
  <meta charset="utf-8" />

  <script src="manager.js"></script>
</head>
<body>

<h1>MySQL functions</h1>

<?php
  $A = $_GET['action'];
  $ID = $_POST['loginName'];
  $PASS = $_POST['loginPass'];
  
  print 'action: ' . $A . '<br>' . 'loginNane: ' . $ID;
  //$Password = $_POST['pass'];

  $db_name = 'test';

  $link = @mysqli_connect('localhost', 'a51', 'a51', $db_name);

  if (!$link) {
    die("Failed to connect to MySQL: " . mysqli_connect_error());
  }

  $result = dbQueryRow($link, "SELECT * FROM loggers WHERE name='tlp'");
  if ($result) {
    printf("Admin: %s\n", $result['admin']);
 
    scriptIt("if (sessionStorage) { sessionStorage.setItem('WEB_ADMIN', '" . $result['admin'] . "'); }");
    $result = null;
  }

  $result = dbQueryRow($link, "select SUBSTRING_INDEX(host, ':', 1) as 'ip' from information_schema.processlist WHERE ID=connection_id()");
  if ($result) {
    printf("IP: %s\n", $result['ip']);
    $result = null;
  }

  function scriptIt($what) {
    $MyVar2 = "?><script language=javascript>" . $what . "</script><?php"; 
    $MyVar2 = str_replace("?>", "", $MyVar2); 
    print $MyVar2."<br><br>";
  }

  function dbQueryRow($link, $sql) {
    $result = mysqli_query($link, $sql);

    $row = null;

    if ($result) {
      $num_rows = mysqli_num_rows($result);
   
      if ($num_rows > 0) {
        $row = mysqli_fetch_array($result, MYSQLI_ASSOC);
      }
   
      mysqli_free_result($result);
    }

    return $row;
  }

  @mysqli_close($link);

  function outputConsole($data) {
    $output = $data;
    if ( is_array( $output ) )
        $output = implode( ',', $output);

    echo "<script>console.log( 'Debug Objects: " . $output . "' );</script>";
  }

?> 

</body>
</html>