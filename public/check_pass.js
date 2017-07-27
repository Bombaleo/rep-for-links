function check_pass() {
  if (document.getElementById('password').value ==
       document.getElementById('confirm_password').value) {
         document.getElementById('submit').disabled = false;
         document.getElementById('message').style.color = 'green';
         document.getElementById('message').innerHTML = 'matching';
  } else {
     document.getElementById('submit').disabled = true
     document.getElementById('message').style.color = 'red';
     document.getElementById('message').innerHTML = 'not matching';
  }
}
